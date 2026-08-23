# 00 — Índice canônico da documentação EduGame

Este índice é a porta de entrada para Claude Code/Claude Desktop e para qualquer agente de engenharia. O projeto completo continua organizado em M0–M11; nenhuma fase posterior invalida contratos anteriores.

## Inicialização do agente
1. `START_HERE.md`
2. `CLAUDE.md`
3. `EDUGAME_CODEX_MASTER_SPEC.md`
4. `ROADMAP_M0_M11.md`
5. gate do marco atual
6. documentos específicos do ticket

## Especificações de produto e engenharia já consolidadas
- `01_PRODUCT_AND_RULES.md` — produto e regras.
- `02_ROLES_AND_PERMISSIONS.md` — papéis, vínculo e autorização.
- `03_SCREEN_CATALOG_AND_ROUTES.md` — telas/rotas.
- `04_DESIGN_SYSTEM.md` + `28_DESIGN_TOKENS_IMPLEMENTABLE.md` — UI.
- `05_LEARNING_QUIZ_REVIEW_ENGINE.md` — aprendizagem, quiz e revisão.
- `06_SCORING_REWARDS_EVENTS.md` — ledgers, recompensas e eventos.
- `07_GAMES_ARENA_MULTIPLAYER.md` — Arcade/Arena.
- `08_AVATAR_200_ANIMALS.md` — Avatar Lab e 200 espécies.
- `09_PET_SYSTEM.md` — Pet.
- `10_DATA_MODEL.md` — dados.
- `11_SERVER_CONTRACTS.md` + `26_API_ERROR_CONTRACT.md` — servidor/API.
- `12_SECURITY_PRIVACY_A11Y.md` — segurança, LGPD e acessibilidade.
- `14_CONTENT_ADMIN_AI.md` + `22_CONTENT_LIFECYCLE.md` — conteúdo e IA.
- `15_IMPLEMENTATION_ROADMAP_GATES.md` + `29_FIRST_SPRINT_BACKLOG.md` — execução.
- `16_TEST_PLAN.md` + `18_DEFINITION_OF_DONE.md` — qualidade.
- `20_OPERATIONAL_READINESS_V1_1.md`, `27_IMPORT_EXPORT_AND_DR.md` — operação/DR.
- `21_SYNC_MATRIX.md` — autoridade e sincronização.
- `23_DATA_RETENTION_MATRIX_TEMPLATE.md` — retenção.
- `24_PERFORMANCE_BUDGETS.md` — budgets.
- `25_FEATURE_ROLLOUT.md` — rollout.

## Claude, MCP e Skills
- `30_CLAUDE_MCP_CONNECTORS_SKILLS.md`
- `31_CLAUDE_EXECUTION_PLAYBOOK.md`
- `32_EXTERNAL_TOOLING_REFERENCES_2026-08-22.md`
- `33_M0_M11_SPEC_MATRIX.md`
- `.mcp.json` — Supabase read-only, project-scoped.
- `.mcp.write.example.json` — exemplo de modo de escrita para dev/staging.
- `.claude/settings.json` — permissões conservadoras.
- `.claude/skills/*/SKILL.md` — skills locais do projeto.

## PWA completa
A antiga visão resumida permanece em `13_PWA_PERFORMANCE_OBSERVABILITY.md`, mas o contrato completo está em `docs/pwa/`:
- `00_PWA_MASTER_SPEC.md`
- `01_INSTALL_MANIFEST_APP_SHELL.md`
- `02_SERVICE_WORKER_CACHE_STRATEGY.md`
- `03_OFFLINE_DATA_INDEXEDDB_SYNC.md`
- `04_AUTH_SECURITY_PRIVACY.md`
- `05_PUSH_NOTIFICATIONS.md`
- `06_PERFORMANCE_A11Y_ADAPTIVE_QUALITY.md`
- `07_OBSERVABILITY_ANALYTICS.md`
- `08_TESTING_RELEASE_INCIDENTS.md`
- `09_M9_IMPLEMENTATION_BACKLOG.md`
- `10_PWA_ACCEPTANCE_TESTS.md`
- `11_BROWSER_SUPPORT_DEGRADATION.md`

## Regra de precedência
Em conflito: decisão mais nova aprovada > ADR > especificação mestre > documento canônico específico > protótipo/referência visual. Nunca inferir que protótipo altera regra de negócio.
