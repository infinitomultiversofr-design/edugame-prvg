# Gate M0-A — Database Foundation

Este Gate substitui semanticamente o antigo “Gate M0” de banco.

## Pré-condições
- [ ] ambiente local/dev/staging
- [ ] migrations em banco limpo
- [ ] seed apenas dev/test
- [ ] service role ausente do frontend
- [ ] usuários Auth reais de teste

## Schema
- [ ] 0001–0008 aplicam sem erro
- [ ] nenhuma PK operacional serial/bigserial
- [ ] classes não apontam para academic_year de outra escola
- [ ] enrollment não aponta para class/year/school incompatíveis

## RLS
- [ ] estudante A vê somente a si
- [ ] professor vê turma atribuída
- [ ] responsável vê estudante vinculado
- [ ] coordenação vê apenas escola própria
- [ ] escola A não lê escola B

## Auth deletion
- [ ] apagar auth.users não apaga students
- [ ] students.user_id torna-se NULL
- [ ] membership/profile de acesso são removidos conforme FK

## Identidade
- [ ] criar conta Auth provisiona user_profiles
- [ ] cliente não insere user_profiles diretamente
- [ ] usuário edita apenas o próprio display_name

## Feature flags
- [ ] catálogo existe
- [ ] override por turma é único
- [ ] precedência funciona
- [ ] escola B não herda override A
- [ ] alteração gera audit log
- [ ] override de usuário exige vínculo ativo na escola
- [ ] flag de turma exige vínculo com a turma

## Audit
- [ ] estudante não insere audit diretamente
- [ ] metadados são mínimos/sanitizados
- [ ] chaves de raw IP/User-Agent conhecidas são rejeitadas
- [ ] PII de rede aninhada e com nome variante também é rejeitada
- [ ] mudanças de vínculo, papel e status de estudante são auditadas
- [ ] auditoria não carrega nome de estudante

## Revogação de acesso
- [ ] professor com membership suspensa perde acesso a estudantes/turma/matrículas
- [ ] responsável com membership revogada perde acesso
- [ ] atribuição docente encerrada corta o acesso
- [ ] helpers de autorização não aceitam usuário arbitrário

## Testes
- [ ] schema_invariants.sql
- [ ] rls_student.sql
- [ ] rls_teacher.sql
- [ ] rls_family.sql
- [ ] rls_management.sql
- [ ] multi_school_isolation.sql
- [ ] scope_integrity.sql
- [ ] feature_flags.sql
- [ ] audit.sql
- [ ] identity_provisioning.sql
- [ ] scripts/m0-gate.mjs com Auth real

A suíte precisa reportar `Result: PASS` com as 140 asserções. Um arquivo que
termine em `Tests: 0` está abortando antes do plano, não passando.

## Aprovação
M0-A só fica **APROVADO** com evidências de todos os itens acima.

Estado e pendências detalhadas em `GATE_M0A_EVIDENCE.md`.
