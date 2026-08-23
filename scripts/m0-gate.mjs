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

function assert(condition, message) {
  if (!condition) throw new Error(`ASSERTION_FAILED: ${message}`)
  console.log(`✅ ${message}`)
}

async function makeUser(label) {
  const email = `m0-${run}-${label}@edugame.test`
  const { data, error } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { purpose: 'm0-gate', label },
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

async function cleanup() {
  console.log('🧹 Limpando fixtures M0...')
  try {
    if (created.studentIds.length) {
      await admin.from('guardian_student_links').delete().in('student_id', created.studentIds)
      await admin.from('enrollments').delete().in('student_id', created.studentIds)
    }
    if (created.classIds.length) {
      await admin.from('teacher_assignments').delete().in('class_id', created.classIds)
      await admin.from('feature_flag_overrides').delete().in('class_id', created.classIds)
    }
    if (created.flagIds.length) {
      await admin.from('feature_flag_catalog').delete().in('id', created.flagIds)
    }
    if (createdUsers.length) {
      await admin.from('school_memberships').delete().in('user_id', createdUsers)
    }
    if (created.studentIds.length) {
      await admin.from('students').delete().in('id', created.studentIds)
    }
    if (created.classIds.length) {
      await admin.from('classes').delete().in('id', created.classIds)
    }
    if (created.yearIds.length) {
      await admin.from('academic_years').delete().in('id', created.yearIds)
    }
    if (created.schoolIds.length) {
      await admin.from('audit_logs').delete().in('school_id', created.schoolIds)
      await admin.from('schools').delete().in('id', created.schoolIds)
    }
    for (const uid of createdUsers) {
      await admin.auth.admin.deleteUser(uid)
    }
  } catch (e) {
    console.error('⚠️ Falha parcial no cleanup:', e.message)
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
  }

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
  const classB = await insert('classes', {
    school_id: schoolB.id, academic_year_id: yearB.id, name: '6º A', grade: '6º ano', code: '6A'
  })
  created.classIds.push(classA.id, classB.id)

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

  const rFlagA = await studentClient.rpc('get_feature_flag', {
    p_key: flag.key,
    p_school_id: schoolA.id,
    p_class_id: classA.id,
  })
  if (rFlagA.error) throw rFlagA.error
  assert(rFlagA.data === true, 'flag de turma está ativa para student A')

  const teacherBClient = await clientFor(users.teacherB.email)
  const rFlagB = await teacherBClient.rpc('get_feature_flag', {
    p_key: flag.key,
    p_school_id: schoolB.id,
    p_class_id: classB.id,
  })
  if (rFlagB.error) throw rFlagB.error
  assert(rFlagB.data === false, 'flag da escola A não vaza para escola B')

  const { data: auditRows, error: auditError } = await admin
    .from('audit_logs')
    .select('action,metadata')
    .eq('resource_type', 'feature_flag_override')
    .eq('school_id', schoolA.id)
  if (auditError) throw auditError
  assert(auditRows.some(x => x.action === 'feature_flag_override_created'), 'mudança de flag gera audit log')

  const rawAudit = await admin.from('audit_logs').insert({
    action: 'm0_raw_pii_should_fail',
    resource_type: 'system',
    metadata: { ip_address: '127.0.0.1' },
  })
  assert(Boolean(rawAudit.error), 'audit log rejeita chave de IP bruto no metadata')

  const deleteResult = await admin.auth.admin.deleteUser(users.tempStudent.id)
  if (deleteResult.error) throw deleteResult.error
  const { data: tempAfter, error: tempAfterError } = await admin
    .from('students')
    .select('id,user_id,edugame_id')
    .eq('id', tempStudent.id)
    .single()
  if (tempAfterError) throw tempAfterError
  assert(tempAfter.id === tempStudent.id && tempAfter.user_id === null, 'apagar Auth preserva estudante e zera user_id')

  // O usuário temp já foi removido; evita tentativa de remoção duplicada no cleanup.
  const ix = createdUsers.indexOf(users.tempStudent.id)
  if (ix >= 0) createdUsers.splice(ix, 1)

  console.log('\n🎉 M0 GATE AUTOMATION: PASSOU')
} catch (error) {
  console.error('\n❌ M0 GATE AUTOMATION: FALHOU')
  console.error(error)
  process.exitCode = 1
} finally {
  await cleanup()
}
