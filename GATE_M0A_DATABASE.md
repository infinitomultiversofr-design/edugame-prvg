# Gate M0-A — Database Foundation

Este Gate substitui semanticamente o antigo “Gate M0” de banco.

## Pré-condições
- [ ] ambiente local/dev/staging
- [ ] migrations em banco limpo
- [ ] seed apenas dev/test
- [ ] service role ausente do frontend
- [ ] usuários Auth reais de teste

## Schema
- [ ] 0001–0007 aplicam sem erro
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

## Feature flags
- [ ] catálogo existe
- [ ] override por turma é único
- [ ] precedência funciona
- [ ] escola B não herda override A
- [ ] alteração gera audit log

## Audit
- [ ] estudante não insere audit diretamente
- [ ] metadados são mínimos/sanitizados
- [ ] chaves de raw IP/User-Agent conhecidas são rejeitadas

## Testes
- [ ] schema_invariants.sql
- [ ] rls_student.sql
- [ ] rls_teacher.sql
- [ ] rls_family.sql
- [ ] rls_management.sql
- [ ] multi_school_isolation.sql
- [ ] scripts/m0-gate.mjs com Auth real

## Aprovação
M0-A só fica **APROVADO** com evidências de todos os itens acima.
