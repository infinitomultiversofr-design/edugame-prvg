/*
 * EDUGAME — Runner do Gate M0-A com Auth real.
 *
 * Cria usuários de verdade em auth.users, exercita as policies pelo PostgREST
 * com JWT de cada papel e remove os fixtures no fim.
 *
 * NÃO RODAR CONTRA PRODUÇÃO. Exige ALLOW_M0_GATE=true e M0_GATE_ENV em
 * dev/staging/local. Mesmo assim, use um projeto Supabase isolado.
 *
 * Mudanças em relação à versão anterior:
 *  - a negação de auditoria ao estudante era testada com o cliente
 *    service_role, o que valida a constraint de PII mas não a negação: o item
 *    do Gate "estudante não insere audit diretamente" ficava sem cobertura;
 *  - o cleanup ignorava o erro de todo delete e só removia overrides por
 *    class_id, deixando fixtures órfãos no banco de dev em silêncio;
 *  - não havia cobertura para revogação de vínculo, escopo de override por
 *    usuário, autorização de flag por turma nem provisionamento de perfil.
 */

import { createClient } from '@supabase/supabase-js'
import crypto from 'node:crypto'

const {
  SUPABASE_URL,
  SUPABASE_ANON_KEY,
  SUPABASE_SERVICE_ROLE_KEY,
  ALLOW_M0_GATE,
  M0_GATE_ENV = 'dev',
} = process.env

if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('Defina SUPABASE_URL, SUPABASE_ANON_KEY e SUPABASE_SERVICE_ROLE_KEY.')
}
if (ALLOW_M0_GATE !== 'true') {
  throw new Error('Defina ALLOW_M0_GATE=true explicitamente.')
}
if (!['dev', 'staging', 'local'].includes(M0_GATE_ENV)) {
  throw new Error(`M0_GATE_ENV=${M0_GATE_ENV} não é permitido para este teste.`)
}

const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
})

const run = crypto.randomBytes(4).toString('hex')
const password = `M0-${crypto.randomBytes(12).toString('base64url')}!`
const createdUsers = []
const created = {
  schoolIds: [],
  yearIds: [],
  classIds: [],
  studentIds: [],
  flagIds: [],
}

let passed = 0

function assert(condition, message) {
  if (!condition) throw new Error(`ASSERTION_FAILED: ${message}`)
  passed += 1
  console.log(`✅ ${message}`)
}

function assertDenied(result, message) {
  assert(Boolean(result.error), message)
}

async function makeUser(label, meta = {}) {
  const email = `m0-${run}-${label}@edugame.test`
  const { data, error } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { purpose: 'm0-gate', label, ...meta },
  })
  if (error) throw error
  createdUsers.push(data.user.id)
  return { id: data.user.id, email }
}

async function clientFor(email) {
  const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  })
  const { error } = await client.auth.signInWithPassword({ email, password })
  if (error) throw error
  return client
}

async function insert(table, row) {
  const { data, error } = await admin.from(table).insert(row).select().single()
  if (error) throw error
  return data
}

async function update(table, patch, match) {
  const { error } = await admin.from(table).update(patch).match(match)
  if (error) throw error
}

// O cleanup anterior engolia qualquer erro. Agora cada remoção é verificada e
// o que sobrar é reportado com o identificador, para poder ser limpo à mão.
const cleanupProblems = []

async function remove(table, column, values) {
  if (!values || values.length === 0) return
  const { error } = await admin.from(table).delete().in(column, values)
  if (error) {
    cleanupProblems.push(`${table} por ${column}: ${error.message}`)
  }
}

async function cleanup() {
  console.log('\n🧹 Limpando fixtures M0...')

  await remove('guardian_student_links', 'student_id', created.studentIds)
  await remove('enrollments', 'student_id', created.studentIds)
  await remove('teacher_assignments', 'class_id', created.classIds)
  // Por flag_id, não por class_id: overrides de escopo school/role/user não têm
  // class_id e ficavam para trás.
  await remove('feature_flag_overrides', 'flag_id', created.flagIds)
  await remove('feature_flag_catalog', 'id', created.flagIds)
  await remove('school_memberships', 'user_id', createdUsers)
  await remove('students', 'id', created.studentIds)
  await remove('classes', 'id', created.classIds)
  await remove('academic_years', 'id', created.yearIds)
  // Depois de todas as remoções acima, para varrer também o que os triggers de
  // auditoria registraram durante a própria limpeza.
  await remove('audit_logs', 'school_id', created.schoolIds)
  await remove('schools', 'id', created.schoolIds)

  for (const uid of createdUsers) {
    const { error } = await admin.auth.admin.deleteUser(uid)
    if (error) cleanupProblems.push(`auth.users ${uid}: ${error.message}`)
  }

  const { data: leftovers } = await admin
    .from('schools')
    .select('id')
    .in('id', created.schoolIds.length ? created.schoolIds : [crypto.randomUUID()])
  if (leftovers && leftovers.length > 0) {
    cleanupProblems.push(`${leftovers.length} escola(s) de fixture ainda no banco`)
  }

  if (cleanupProblems.length > 0) {
    console.error('⚠️  CLEANUP INCOMPLETO — remova manualmente:')
    for (const p of cleanupProblems) console.error(`   - ${p}`)
    process.exitCode = 1
  } else {
    console.log('🧼 Cleanup verificado: nenhum fixture restante.')
  }
}

try {
  const users = {
    studentA: await makeUser('student-a'),
    studentA2: await makeUser('student-a2'),
    teacherA: await makeUser('teacher-a'),
    familyA: await makeUser('family-a'),
    coordinatorA: await makeUser('coordinator-a'),
    adminA: await makeUser('admin-a'),
    directorA: await makeUser('director-a'),
    teacherB: await makeUser('teacher-b'),
    tempStudent: await makeUser('temp-delete'),
    named: await makeUser('named', { display_name: 'Nome Escolhido' }),
  }

  // ---------------------------------------------------------------- identidade
  const { data: namedProfile, error: namedProfileError } = await admin
    .from('user_profiles')
    .select('display_name')
    .eq('user_id', users.named.id)
    .maybeSingle()
  if (namedProfileError) throw namedProfileError
  assert(
    namedProfile !== null,
    'criar conta Auth provisiona user_profiles automaticamente'
  )
  assert(
    namedProfile.display_name === 'Nome Escolhido',
    'display_name do perfil vem do metadata da conta'
  )

  // ------------------------------------------------------------------- fixture
  const schoolA = await insert('schools', {
    name: `M0 Escola A ${run}`, short_name: 'M0-A', slug: `m0-a-${run}`
  })
  const schoolB = await insert('schools', {
    name: `M0 Escola B ${run}`, short_name: 'M0-B', slug: `m0-b-${run}`
  })
  created.schoolIds.push(schoolA.id, schoolB.id)

  const yearA = await insert('academic_years', {
    school_id: schoolA.id, year: 2026, start_date: '2026-02-01', end_date: '2026-12-15'
  })
  const yearB = await insert('academic_years', {
    school_id: schoolB.id, year: 2026, start_date: '2026-02-01', end_date: '2026-12-15'
  })
  created.yearIds.push(yearA.id, yearB.id)

  const classA = await insert('classes', {
    school_id: schoolA.id, academic_year_id: yearA.id, name: '6º A', grade: '6º ano', code: '6A'
  })
  const classA2 = await insert('classes', {
    school_id: schoolA.id, academic_year_id: yearA.id, name: '7º A', grade: '7º ano', code: '7A'
  })
  const classB = await insert('classes', {
    school_id: schoolB.id, academic_year_id: yearB.id, name: '6º A', grade: '6º ano', code: '6A'
  })
  created.classIds.push(classA.id, classA2.id, classB.id)

  const membershipRows = [
    [users.studentA, schoolA.id, 'student'],
    [users.studentA2, schoolA.id, 'student'],
    [users.teacherA, schoolA.id, 'teacher'],
    [users.familyA, schoolA.id, 'family'],
    [users.coordinatorA, schoolA.id, 'coordinator'],
    [users.adminA, schoolA.id, 'admin'],
    [users.directorA, schoolA.id, 'director'],
    [users.teacherB, schoolB.id, 'teacher'],
    [users.tempStudent, schoolA.id, 'student'],
  ].map(([u, school_id, role]) => ({
    user_id: u.id, school_id, role, status: 'active'
  }))
  const { error: membershipError } = await admin.from('school_memberships').insert(membershipRows)
  if (membershipError) throw membershipError

  const studentA = await insert('students', {
    edugame_id: `M0-${run}-A1`,
    user_id: users.studentA.id,
    school_id: schoolA.id,
    official_name: 'Aluno A1',
    display_name: 'Aluno A1',
  })
  const studentA2 = await insert('students', {
    edugame_id: `M0-${run}-A2`,
    user_id: users.studentA2.id,
    school_id: schoolA.id,
    official_name: 'Aluno A2',
    display_name: 'Aluno A2',
  })
  const studentB = await insert('students', {
    edugame_id: `M0-${run}-B1`,
    school_id: schoolB.id,
    official_name: 'Aluno B1',
    display_name: 'Aluno B1',
  })
  const tempStudent = await insert('students', {
    edugame_id: `M0-${run}-TEMP`,
    user_id: users.tempStudent.id,
    school_id: schoolA.id,
    official_name: 'Aluno Temporário',
    display_name: 'Aluno Temporário',
  })
  created.studentIds.push(studentA.id, studentA2.id, studentB.id, tempStudent.id)

  const { error: enrollmentError } = await admin.from('enrollments').insert([
    {
      student_id: studentA.id, school_id: schoolA.id, academic_year_id: yearA.id,
      class_id: classA.id, status: 'active'
    },
    {
      student_id: studentA2.id, school_id: schoolA.id, academic_year_id: yearA.id,
      class_id: classA.id, status: 'active'
    },
    {
      student_id: studentB.id, school_id: schoolB.id, academic_year_id: yearB.id,
      class_id: classB.id, status: 'active'
    },
  ])
  if (enrollmentError) throw enrollmentError

  const { error: teacherError } = await admin.from('teacher_assignments').insert([
    {
      user_id: users.teacherA.id, school_id: schoolA.id, academic_year_id: yearA.id,
      class_id: classA.id, subject_area: 'general'
    },
    {
      user_id: users.teacherB.id, school_id: schoolB.id, academic_year_id: yearB.id,
      class_id: classB.id, subject_area: 'general'
    },
  ])
  if (teacherError) throw teacherError

  const { error: guardianError } = await admin.from('guardian_student_links').insert({
    guardian_user_id: users.familyA.id,
    student_id: studentA.id,
    school_id: schoolA.id,
    status: 'active',
    verified_at: new Date().toISOString(),
  })
  if (guardianError) throw guardianError

  const studentClient = await clientFor(users.studentA.email)
  const teacherClient = await clientFor(users.teacherA.email)
  const familyClient = await clientFor(users.familyA.email)
  const coordinatorClient = await clientFor(users.coordinatorA.email)

  // ------------------------------------------------------------- RLS: leitura
  let q = await studentClient.from('students').select('id,edugame_id')
  if (q.error) throw q.error
  assert(q.data.length === 1 && q.data[0].id === studentA.id, 'student A vê apenas a si mesmo')

  q = await teacherClient.from('students').select('id,school_id')
  if (q.error) throw q.error
  assert(q.data.length === 2, 'teacher A vê os 2 estudantes da turma A')
  assert(!q.data.some(x => x.id === studentB.id), 'teacher A não vê estudante da escola B')

  q = await familyClient.from('students').select('id')
  if (q.error) throw q.error
  assert(q.data.length === 1 && q.data[0].id === studentA.id, 'responsável vê apenas estudante vinculado')

  q = await coordinatorClient.from('schools').select('id')
  if (q.error) throw q.error
  assert(q.data.length === 1 && q.data[0].id === schoolA.id, 'coordenação A não vê escola B')

  // ------------------------------------------------------------ RLS: escrita
  // O item "estudante não insere audit diretamente" precisa do cliente do
  // aluno; com service_role a inserção é legítima e o teste não prova nada.
  assertDenied(
    await studentClient.from('audit_logs').insert({
      action: 'forjado_pelo_cliente', resource_type: 'system',
    }),
    'estudante não insere registro de auditoria'
  )
  assertDenied(
    await studentClient.from('students').update({ display_name: 'hack' }).eq('id', studentA.id),
    'estudante não altera o próprio registro escolar'
  )
  assertDenied(
    await studentClient.from('school_memberships').insert({
      user_id: users.studentA.id, school_id: schoolA.id, role: 'director',
    }),
    'estudante não se promove a director'
  )
  assertDenied(
    await familyClient.from('students').update({ display_name: 'apelido' }).eq('id', studentA.id),
    'responsável permanece somente leitura'
  )
  assertDenied(
    await teacherClient.from('enrollments').insert({
      student_id: studentB.id, school_id: schoolA.id,
      academic_year_id: yearA.id, class_id: classA.id,
    }),
    'professor não matricula estudante pelo cliente'
  )

  const studentAudit = await studentClient.from('audit_logs').select('id')
  if (studentAudit.error) throw studentAudit.error
  assert(studentAudit.data.length === 0, 'estudante não lê auditoria')

  // ------------------------------------------------------- revogação de acesso
  await update('school_memberships', { status: 'suspended' },
    { user_id: users.teacherA.id, school_id: schoolA.id })

  q = await teacherClient.from('students').select('id')
  if (q.error) throw q.error
  assert(q.data.length === 0, 'professor com vínculo suspenso perde acesso aos estudantes')

  await update('school_memberships', { status: 'active' },
    { user_id: users.teacherA.id, school_id: schoolA.id })

  q = await teacherClient.from('students').select('id')
  if (q.error) throw q.error
  assert(q.data.length === 2, 'reativar o vínculo devolve o acesso do professor')

  await update('guardian_student_links', { status: 'revoked' },
    { guardian_user_id: users.familyA.id, student_id: studentA.id })

  q = await familyClient.from('students').select('id')
  if (q.error) throw q.error
  assert(q.data.length === 0, 'vínculo de responsável revogado corta o acesso')

  await update('guardian_student_links', { status: 'active' },
    { guardian_user_id: users.familyA.id, student_id: studentA.id })

  // ------------------------------------------------------------ feature flags
  const flag = await insert('feature_flag_catalog', {
    key: `m0_flag_${run}`, default_enabled: false, description: 'M0 gate'
  })
  created.flagIds.push(flag.id)

  const { error: flagInsertError } = await coordinatorClient
    .from('feature_flag_overrides')
    .insert({
      flag_id: flag.id,
      scope_type: 'class',
      school_id: schoolA.id,
      class_id: classA.id,
      enabled: true,
      reason: 'M0 gate class rollout',
    })
  if (flagInsertError) throw flagInsertError

  assertDenied(
    await coordinatorClient.from('feature_flag_overrides').insert({
      flag_id: flag.id, scope_type: 'global', enabled: true,
    }),
    'coordenação não cria override global'
  )
  assertDenied(
    await coordinatorClient.from('feature_flag_overrides').insert({
      flag_id: flag.id, scope_type: 'user', school_id: schoolA.id,
      user_id: users.teacherB.id, enabled: true,
    }),
    'coordenação não cria override de usuário de outra escola'
  )

  const rFlagA = await studentClient.rpc('get_feature_flag', {
    p_key: flag.key,
    p_school_id: schoolA.id,
    p_class_id: classA.id,
  })
  if (rFlagA.error) throw rFlagA.error
  assert(rFlagA.data === true, 'flag de turma está ativa para student A')

  const rFlagOther = await studentClient.rpc('get_feature_flag', {
    p_key: flag.key,
    p_school_id: schoolA.id,
    p_class_id: classA2.id,
  })
  assert(Boolean(rFlagOther.error), 'estudante não resolve flag de turma em que não está')

  const teacherBClient = await clientFor(users.teacherB.email)
  const rFlagB = await teacherBClient.rpc('get_feature_flag', {
    p_key: flag.key,
    p_school_id: schoolB.id,
    p_class_id: classB.id,
  })
  if (rFlagB.error) throw rFlagB.error
  assert(rFlagB.data === false, 'flag da escola A não vaza para escola B')

  const rFlagCross = await teacherBClient.rpc('get_feature_flag', {
    p_key: flag.key,
    p_school_id: schoolA.id,
    p_class_id: classA.id,
  })
  assert(Boolean(rFlagCross.error), 'professor da escola B não resolve flag da escola A')

  // ----------------------------------------------------------------- auditoria
  const { data: auditRows, error: auditError } = await admin
    .from('audit_logs')
    .select('action,metadata')
    .eq('resource_type', 'feature_flag_override')
    .eq('school_id', schoolA.id)
  if (auditError) throw auditError
  assert(auditRows.some(x => x.action === 'feature_flag_override_created'), 'mudança de flag gera audit log')

  const { data: membershipAudit, error: membershipAuditError } = await admin
    .from('audit_logs')
    .select('action')
    .eq('resource_type', 'school_memberships')
    .eq('school_id', schoolA.id)
  if (membershipAuditError) throw membershipAuditError
  assert(membershipAudit.length > 0, 'mudança de vínculo escolar gera audit log')

  assertDenied(
    await admin.from('audit_logs').insert({
      action: 'm0_raw_pii_should_fail', resource_type: 'system',
      metadata: { ip_address: '127.0.0.1' },
    }),
    'audit log rejeita chave de IP bruto no metadata'
  )
  assertDenied(
    await admin.from('audit_logs').insert({
      action: 'm0_nested_pii_should_fail', resource_type: 'system',
      metadata: { ctx: { request: { ip_address: '127.0.0.1' } } },
    }),
    'audit log rejeita IP bruto aninhado no metadata'
  )
  assertDenied(
    await admin.from('audit_logs').insert({
      action: 'm0_variant_pii_should_fail', resource_type: 'system',
      metadata: { clientIp: '127.0.0.1' },
    }),
    'audit log rejeita variação de nome de chave de IP'
  )

  // -------------------------------------------------------- exclusão de conta
  const deleteResult = await admin.auth.admin.deleteUser(users.tempStudent.id)
  if (deleteResult.error) throw deleteResult.error
  // O usuário já foi removido; evita tentativa duplicada no cleanup.
  const ix = createdUsers.indexOf(users.tempStudent.id)
  if (ix >= 0) createdUsers.splice(ix, 1)

  const { data: tempAfter, error: tempAfterError } = await admin
    .from('students')
    .select('id,user_id,edugame_id')
    .eq('id', tempStudent.id)
    .single()
  if (tempAfterError) throw tempAfterError
  assert(
    tempAfter.id === tempStudent.id && tempAfter.user_id === null,
    'apagar Auth preserva estudante e zera user_id'
  )

  const { data: tempProfile, error: tempProfileError } = await admin
    .from('user_profiles')
    .select('user_id')
    .eq('user_id', users.tempStudent.id)
    .maybeSingle()
  if (tempProfileError) throw tempProfileError
  assert(tempProfile === null, 'apagar Auth remove o perfil (PII de autenticação)')

  console.log(`\n🎉 M0 GATE AUTOMATION: PASSOU (${passed} asserções)`)
} catch (error) {
  console.error('\n❌ M0 GATE AUTOMATION: FALHOU')
  console.error(error)
  process.exitCode = 1
} finally {
  await cleanup()
}
