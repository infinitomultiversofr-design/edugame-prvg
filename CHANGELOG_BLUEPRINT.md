# Blueprint Changelog

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
