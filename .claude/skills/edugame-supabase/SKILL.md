---
name: edugame-supabase
description: Trabalha com Supabase no EduGame: schema, migrations, RLS, Auth, RPCs, logs e validação do Gate M0. Use em tarefas de banco, autenticação, segurança de dados, migrations, Edge Functions ou integração via MCP.
---
# Supabase do EduGame

- Comece em modo MCP read-only. Use escrita somente quando o ticket autorizar e houver ambiente dev/staging isolado.
- Escopo obrigatório por `SUPABASE_PROJECT_REF`; nunca conecte MCP sem escopo a uma organização inteira para este projeto.
- Leia `GATE_M0A_DATABASE.md`, `docs/10_DATA_MODEL.md`, `docs/11_SERVER_CONTRACTS.md`, `docs/12_SECURITY_PRIVACY_A11Y.md` e migrations relevantes.
- Use ferramentas Supabase MCP qualificadas quando disponíveis; confirme tabelas/migrations antes de assumir estado.
- Toda alteração de schema deve ser migration versionada; não fazer mudança manual sem registrar.
- RLS falha fechada. Cliente nunca decide acerto, pontos, desbloqueio, identidade de terceiros ou autorização.
- `service_role` nunca entra no bundle, Skill, CLAUDE.md, Git ou chat.
- Após mudança: testes RLS com Auth real, advisors, tipos TS, lint/typecheck/build e evidência do gate.
