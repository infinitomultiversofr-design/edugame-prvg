# EduGame — Claude Quickstart

## 1. Abra a pasta
Descompacte o pacote e abra a pasta `EduGame/` no terminal/ambiente do Claude Code.

## 2. Configure o Supabase de desenvolvimento
Defina somente o project ref do ambiente dev/staging:

```bash
export SUPABASE_PROJECT_REF="SEU_PROJECT_REF_DE_DEV"
```

Não coloque token, senha, `service_role` ou PAT em `CLAUDE.md`.

## 3. Inicie Claude Code

```bash
claude
```

Depois execute `/mcp`, escolha `supabase` e faça login/autorização pelo navegador.

## 4. Primeira mensagem
Use `PROMPTS/03_CLAUDE_MCP_BOOTSTRAP.md`.

## 5. Estado esperado
O agente deve responder que M0-A ainda precisa de evidência real em Supabase isolado e que M1 não pode começar antes do Gate M0 Final.

## 6. Escrita no Supabase
O pacote abre em modo read-only. Quando chegar um ticket que realmente exige migration/RPC/Edge Function em dev/staging, siga `docs/30_CLAUDE_MCP_CONNECTORS_SKILLS.md` para habilitar temporariamente a configuração de escrita.

## 7. PWA
Quando chegar ao M9, o ponto de entrada é `docs/pwa/00_PWA_MASTER_SPEC.md` e o fechamento é `docs/pwa/10_PWA_ACCEPTANCE_TESTS.md`.
