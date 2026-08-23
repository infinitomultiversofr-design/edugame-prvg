# Blueprint Changelog

## Migration Pack M0 — Revision 2.2 — 2026-08-23
Adicionado:
- `supabase/migrations/0008_authz_hardening.sql`;
- `supabase/tests/scope_integrity.sql`, `feature_flags.sql`, `audit.sql`,
  `identity_provisioning.sql`;
- `supabase/tests/helpers/m0_fixture.psql` (fixture única);
- `scripts/m0-local-verify.sh` e `scripts/_local_supabase_shim.sql`;
- `GATE_M0A_EVIDENCE.md`.

Corrigido:
1. A suíte pgTAP não executava: `plan()` falhava em `_set` porque `search_path`
   não incluía o schema da extensão. Zero asserções rodavam.
2. Vínculo escolar suspenso ou atribuição docente encerrada não revogavam o
   acesso aos dados do estudante.
3. Helpers `private.*` recebiam o usuário como argumento e eram executáveis por
   `authenticated`, permitindo consultar vínculos de terceiros.
4. `user_profiles` não tinha caminho de criação.
5. Override de flag por usuário aceitava alvo de outra escola e distinguia UUID
   inexistente de UUID existente.
6. `get_feature_flag` não exigia vínculo com a turma consultada.
7. CHECK de PII do audit só olhava chaves de topo com nome exato.
8. Auditoria cobria apenas feature flags.
9. Os testes desligavam FKs e triggers com `session_replication_role = replica`,
   parâmetro que também exige superusuário.

Em aberto (exigem ADR):
- precedência do resolver de flags impede kill-switch global;
- ausência de `FORCE ROW LEVEL SECURITY`.

## v1.1 — 2026-08-22
Adicionado:
- ERD/invariantes operacionais;
- Sync Matrix;
- lifecycle/versionamento de conteúdo;
- template institucional de retenção;
- performance budgets;
- rollout hierárquico;
- API error contract;
- import/export/DR;
- tokens implementáveis;
- Sprint 1 executável.

Correções explícitas em relação ao rascunho v1.1:
1. Papéis não ficam numa única coluna `users.role`; usamos memberships/assignments.
2. Não hardcodamos “eliminação em 1 ano” como regra jurídica universal.
3. Quiz offline não é considerado enviado/validado; uma escolha local é apenas rascunho.
4. Não prometemos “Background Sync polyfill” equivalente ao SyncManager.
5. Migração pode preservar pontos históricos do próprio EduGame, mas nunca converte nota acadêmica em ponto.
6. RPO/RTO só são declarados atingidos após rotina e restore drill comprovados.
