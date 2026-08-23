# LEGACY ALIAS — Gate M0-A Database Foundation

Este arquivo foi preservado para compatibilidade com referências anteriores.
A versão canônica atual é `GATE_M0A_DATABASE.md`.

O Gate M0 completo da aplicação está em `GATE_M0_FINAL.md`.

---

# EduGame — Gate M0

## Pré-condições
- [ ] ambiente local/dev/staging
- [ ] migrations aplicadas em banco limpo
- [ ] `seed.sql` executado apenas em dev/test
- [ ] signup público conforme política do projeto
- [ ] service role nunca presente no frontend

## 1. Schema
- [ ] 0001–0007 aplicam sem erro
- [ ] nenhuma PK operacional serial/bigserial
- [ ] classes não podem apontar para academic_year de outra escola
- [ ] enrollment não pode apontar para class/year/school incompatíveis

## 2. RLS
- [ ] estudante A vê somente a si
- [ ] professor vê turma atribuída
- [ ] responsável vê estudante vinculado
- [ ] coordenação vê apenas escola própria
- [ ] escola A não lê B

## 3. Auth deletion
- [ ] apagar auth.users não apaga `students`
- [ ] `students.user_id` torna-se NULL
- [ ] membership/profile de acesso são removidos conforme FK

## 4. Feature flags
- [ ] catalog existe
- [ ] override de turma é único
- [ ] precedência funciona
- [ ] escola B não herda override A
- [ ] mudança é auditada

## 5. Audit
- [ ] sem INSERT direto do estudante
- [ ] raw IP/user-agent proibidos nas chaves conhecidas
- [ ] metadados do log são mínimos

## 6. Testes
- [ ] schema_invariants.sql
- [ ] rls_student.sql
- [ ] rls_teacher.sql
- [ ] rls_family.sql
- [ ] rls_management.sql
- [ ] multi_school_isolation.sql
- [ ] scripts/m0-gate.mjs com Auth real

## Condição
M0 só fica **APROVADO** quando todos os itens acima tiverem evidência registrada.
