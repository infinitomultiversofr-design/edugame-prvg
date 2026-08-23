# Gate M0-A — Evidência de revisão e hardening

Data: 2026-08-23
Escopo: `supabase/migrations/0001`–`0008`, `supabase/tests/`, `scripts/m0-gate.mjs`
Ambiente da evidência: PostgreSQL 16.13 local + shim do ambiente Supabase
(`scripts/_local_supabase_shim.sql`), pgTAP 1.3.2

> **Este documento não aprova o Gate M0-A.** Ele registra o que foi revisado,
> o que foi corrigido e o que ainda falta. A aprovação continua dependendo de
> `scripts/m0-gate.mjs` executado com Auth real contra um Supabase dev/staging
> isolado — o que não pode ser produzido em ambiente local.

---

## 1. Resumo

A revisão das migrations 0001–0007 e da suíte pgTAP encontrou **quatro
bloqueadores**, **dois achados altos**, **sete médios** e **seis baixos**.
A migration `0008_authz_hardening.sql` corrige os que são de banco; a suíte
pgTAP foi reescrita; `m0-gate.mjs` foi corrigido e ampliado.

| | Antes | Depois |
|---|---|---|
| Migrations | 7 | 8 |
| Arquivos de teste pgTAP | 6 | 10 |
| Asserções pgTAP | 19 (nenhuma executável) | 140, todas passando |
| Asserções de negação de escrita | 0 | 27 |
| Asserções do runner de Gate | 8 | 30 |

O núcleo de RLS de 0001–0007 estava correto: as 11 verificações de
visibilidade por papel reproduzem exatamente o esperado, antes e depois da
0008. Os problemas estavam nas bordas — revogação, provisionamento, superfície
de funções — e na suíte que deveria tê-los pego.

---

## 2. Bloqueadores encontrados e corrigidos

### B0 — A suíte pgTAP nunca executou

Os 6 arquivos abortavam na primeira instrução:

```
ERROR:  function _set(unknown, integer) does not exist
CONTEXT: PL/pgSQL function extensions.plan(integer) line 32 at PERFORM
Result: FAIL   (Tests: 0)
```

pgTAP chama as próprias funções internas sem qualificar schema. Com a extensão
em `extensions` e `search_path` sem ela, `plan()` falha e o arquivo inteiro é
descartado. As "6 evidências SQL" listadas no Gate produziam zero asserções em
qualquer ambiente.

**Correção:** `SET LOCAL search_path TO extensions, public;` em todos os
arquivos, logo após o `CREATE EXTENSION`.

### B1 — Vínculo suspenso mantinha acesso aos dados do estudante

`private.is_teacher_of_class` e `is_teacher_of_student` liam apenas
`teacher_assignments`; `is_guardian_of_student` lia apenas o status do link.
Nenhum consultava `school_memberships.status`.

Medido antes da correção, com o professor em `status='suspended'`:

```
is_member_of_school(prof A, escola A) ..... f     ← já não é membro
prof suspenso -> students ................. 2     ← acesso total mantido
prof suspenso -> classes .................. 1
prof suspenso -> enrollments .............. 2
prof suspenso -> schools .................. 0     ← só isso caía
```

Depois da 0008, os quatro passam a 0, e reativar o vínculo devolve o acesso.
O mesmo vale para o responsável com membership `family` revogada.

**Correção:** os três helpers passaram a exigir membership ativa com o papel
correspondente. `teacher_assignments` ganhou `status`/`ended_at` (invariante 5:
inativar, não apagar), e a unicidade virou índice parcial sobre as atribuições
vigentes, para não bloquear recontratação.

### B2 — Os testes desativavam as garantias que o Gate manda provar

Todos os 5 arquivos de RLS abriam com
`SET LOCAL session_replication_role = replica`, que desliga FK triggers **e** os
triggers `assert_teacher_membership` / `assert_guardian_membership`.

| Violação | Modo normal | Sob `replica` |
|---|---|---|
| turma em ano letivo de outra escola | `ERROR ... classes_year_same_school_fk` | não coberta |
| matrícula em turma de outra escola | `ERROR ... enrollment_class_scope_fk` | **aceita** |
| atribuição a quem não tem vínculo docente | `ERROR: TEACHER_MEMBERSHIP_REQUIRED` | **aceita** |

Os itens "classes não apontam para academic_year de outra escola" e
"enrollment não aponta para class/year/school incompatíveis" tinham cobertura
zero, e remover as constraints não quebraria teste algum.

**Correção:** a fixture não desliga mais nada; os usuários são criados de
verdade em `auth.users`. O arquivo novo `scope_integrity.sql` cobre as FKs
compostas, os triggers de vínculo e as unicidades — 12 asserções.

### B3 — `session_replication_role` exige superusuário

Confirmado com uma role `NOSUPERUSER`:

```
ERROR:  permission denied to set parameter "session_replication_role"
```

No Supabase hospedado o papel `postgres` não é superusuário, então a suíte
antiga só rodaria em stack local — enquanto o Gate a exige como evidência de um
projeto dev/staging isolado.

**Correção:** eliminada junto com B2. A suíte atual não usa parâmetros
privilegiados e roda em qualquer projeto Supabase.

### B4 — `user_profiles` não tinha caminho de criação

Sem policy de INSERT, sem GRANT de INSERT e sem trigger em `auth.users`. Toda
conta nascia sem perfil e a policy `user_profiles_update_self` era inalcançável:

```
aluno tenta criar o próprio perfil -> ERROR: permission denied for table user_profiles
```

**Correção:** trigger `on_auth_user_created` (SECURITY DEFINER) que provisiona
o perfil a partir de `raw_user_meta_data.display_name`, depois `full_name`,
depois o local-part do e-mail, com fallback final; mais backfill das contas
existentes. O perfil continua sendo criado pelo servidor — o cliente segue sem
INSERT.

---

## 3. Achados altos

### A1 — Helpers `private.*` eram um oráculo de vínculos

Todos recebiam `p_user_id` como argumento e tinham `EXECUTE` para
`authenticated`. O grant é necessário (policies são avaliadas com o papel do
chamador), a assinatura não. Medido como aluno A1:

```
lê a linha do aluno A2 (RLS) ........................ 0   ← bloqueado
is_teacher_of_student(prof A, aluno A2) ............. t   ← confirma que A2 existe e quem o ensina
is_guardian_of_student(responsável, aluno A1) ....... t
is_teacher_of_student(prof B, aluno B1) ............. t   ← atravessa escola
can_manage_school(coord A, escola A) ................ t   ← mapeia a hierarquia
```

**Correção:** os 9 helpers de decisão passaram a ler `auth.uid()` internamente e
receber apenas o recurso. As 12 policies foram reapontadas e as versões de dois
argumentos foram removidas. `schema_invariants.sql` tem uma asserção de
regressão que falha se alguma voltar a aceitar um usuário arbitrário.

### A2 — Override de flag por usuário aceitava alvo de outra escola

A coordenação da escola A criava override `user` mirando o professor da escola
B, e um UUID inexistente devolvia erro de FK diferente — oráculo de existência
de conta.

**Correção:** trigger `assert_flag_override_scope` exige membership ativa do
alvo na escola do override, com **a mesma mensagem** nos dois casos
(`FLAG_OVERRIDE_USER_NOT_IN_SCHOOL`), fechando o oráculo.

---

## 4. Achados médios

| # | Achado | Situação |
|---|---|---|
| M1 | `get_feature_flag` validava só a escola: aluno de 6A lia a flag de 7A (`true`) | Corrigido — exige `can_read_class` |
| M2 | Escopo sempre vence `priority`: `global(true, prio 99)` perde para `school(false, prio 0)` | **Em aberto — precisa de ADR** |
| M3 | Chave desconhecida virava `false` silencioso | Corrigido — `RAISE WARNING` no log, retorno inalterado |
| M4 | CHECK de PII só de topo e por nome exato: `{"ctx":{"ip_address"}}` e `{"clientIp"}` passavam | Corrigido — função recursiva com normalização de nome |
| M5 | Auditoria cobria só feature flags | Corrigido — triggers em memberships, guardian links, teacher assignments, students e enrollments |
| M6 | `m0-gate.mjs` testava rejeição de auditoria com cliente `service_role`, não com aluno | Corrigido |
| M7 | `cleanup()` ignorava erro de todo delete e só removia overrides por `class_id` | Corrigido — erros verificados e reportados; remoção por `flag_id` |

### Sobre M2 — precedência do resolver

Comportamento atual, fixado por teste em `feature_flags.sql`:

```
user > class > role > school > global      (priority só desempata dentro do escopo)
```

A consequência é que **não existe kill-switch global**: um override `global`
com `enabled=false` e `priority` máxima não desliga uma escola que tenha
override próprio. Para um mecanismo de rollout isso é um risco operacional
real. Mudar a semântica é decisão de arquitetura e exige ADR — por isso a 0008
não mexe nisso, apenas documenta e testa o comportamento vigente.

---

## 5. Achados baixos

| # | Achado | Situação |
|---|---|---|
| L1 | `schema_invariants.sql` só verificava existência de 8 tabelas/colunas | Reescrito — 16 asserções sobre os invariantes reais |
| L2 | Todas as asserções eram contagens positivas; nenhuma negação de escrita | 27 asserções de negação distribuídas pela suíte |
| L3 | Fixture de ~70 linhas duplicada em 5 arquivos | Extraída para `tests/helpers/m0_fixture.psql` |
| L4 | `feature_flag_catalog` legível com `USING (true)` | Corrigido — exige vínculo ativo |
| L5 | Nenhuma tabela com `FORCE ROW LEVEL SECURITY` | **Em aberto — ver abaixo** |
| L6 | `teacher_assignments` sem `status`/`ended_at`, contra o invariante 5 | Corrigido |

### Sobre L5 — FORCE ROW LEVEL SECURITY

Ligar `FORCE RLS` sujeitaria o dono das tabelas às policies e quebraria os
triggers de auditoria, que inserem em `audit_logs` — tabela sem policy de
INSERT por decisão de projeto. Fazer isso direito exige decidir como a
auditoria escreve sob RLS forçada. Fica em aberto; hoje o risco é que qualquer
função `SECURITY DEFINER` de aplicação pertencente a `postgres` contorne o RLS
sem aviso.

---

## 6. O que foi verificado e está correto

Confirmado empiricamente, antes e depois da 0008:

- as 8 migrations aplicam limpas em banco vazio (PostgreSQL 16);
- as 12 tabelas têm RLS habilitada e ao menos uma policy;
- toda escrita de cliente testada é negada — `students`, `enrollments`,
  `school_memberships`, `audit_logs`, `schools`, `guardian_student_links`;
- INSERT/DELETE por cliente existe apenas em `feature_flag_overrides`;
- as FKs compostas e os triggers de vínculo bloqueiam estado inconsistente;
- as correções que o `README.md` atribui à Revision 2.1 estão de fato no
  código: `search_path` qualificado em toda função, colunas tipadas por escopo
  de flag, `user_profiles` em CASCADE com `students.user_id` em SET NULL,
  policies delegando a helpers, `(SELECT auth.uid())` para virar initplan;
- semântica de exclusão de conta:

```
antes  -> students.user_id=aaaa…01   user_profiles=1  memberships=1
DELETE FROM auth.users
depois -> students=1  user_id=NULL  edugame_id=M0-A-001  enrollments=1
          user_profiles=0  memberships=0
```

---

## 7. Suíte de testes

```
tests/
  helpers/m0_fixture.psql        fixture única, sem desligar triggers/FKs
  schema_invariants.sql     16   invariantes estruturais e superfície de autorização
  rls_student.sql           17   visibilidade + 8 negações de escrita
  rls_teacher.sql           16   visibilidade + revogação + 4 negações
  rls_family.sql            13   somente leitura + revogação por vínculo e por link
  rls_management.sql        15   escopo de escola + rollout autorizado e negado
  multi_school_isolation.sql 13  outra escola + conta sem vínculo + auditoria
  scope_integrity.sql       12   FKs compostas, triggers de vínculo, unicidades
  feature_flags.sql         12   precedência, isolamento, unicidade, autorização
  audit.sql                 13   cobertura, PII recursiva, leitura por papel
  identity_provisioning.sql 13   provisionamento de perfil e exclusão de conta
                           ────
                            140
```

Prova de que a suíte não é vacuosa — a mesma suíte contra o schema **sem** a
0008:

```
Files=10, Tests=131,  Result: FAIL
23 asserções falhando, cobrindo B1, B4, A1, A2, M1, M4, M5 e L4
```

---

## 8. Como reproduzir

Sem Supabase, em qualquer PostgreSQL com pgTAP:

```bash
PGHOST=/var/run/postgresql PGUSER=postgres ./scripts/m0-local-verify.sh
```

Com Supabase local:

```bash
supabase db reset
supabase test db
```

Gate com Auth real (obrigatório para aprovação, projeto isolado):

```bash
cd scripts && npm install
ALLOW_M0_GATE=true M0_GATE_ENV=dev \
SUPABASE_URL=... SUPABASE_ANON_KEY=... SUPABASE_SERVICE_ROLE_KEY=... \
npm run m0:gate
```

---

## 9. Pendências para aprovar o Gate M0-A

1. Executar `scripts/m0-gate.mjs` contra Supabase dev/staging isolado e anexar
   a saída. **Nada substitui isso** — o shim local reproduz `auth.uid()` e os
   papéis, não o PostgREST nem o `service_role` da plataforma.
2. Rodar `supabase test db` no projeto isolado e confirmar as 140 asserções.
3. Confirmar que o trigger `on_auth_user_created` pôde ser criado em
   `auth.users` no projeto (a migration exige que o papel de deploy tenha essa
   permissão; é o padrão do Supabase, mas precisa de confirmação).
4. Rodar os advisors do Supabase (security + performance) e anexar o resultado.
5. Decidir M2 (kill-switch global) e L5 (FORCE RLS) por ADR, ou registrar
   aceitação explícita do comportamento atual.
6. Confirmar que nenhuma `service_role` key aparece em bundle, Skill, CLAUDE.md
   ou Git.

Enquanto 1–4 não existirem como saída real, o Gate M0-A permanece
**NÃO APROVADO** e o M1 continua bloqueado.
