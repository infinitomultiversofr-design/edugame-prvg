# 32 — Referências externas de tooling — snapshot 22/08/2026

Use estas fontes apenas para comportamento de ferramentas externas. Regras do produto continuam canônicas neste repositório.

## Supabase
- MCP Server: https://supabase.com/docs/guides/ai-tools/mcp
- AI Tools: https://supabase.com/docs/guides/ai-tools
- Plugins/Agent Skills: https://supabase.com/docs/guides/ai-tools/plugins
- Conector oficial Claude (anúncio): https://supabase.com/blog/claude-connector

Pontos verificados no snapshot:
- MCP remoto usa OAuth/browser login; PAT não é necessário no fluxo normal.
- É possível restringir por `project_ref`, `read_only` e grupos de features.
- Supabase recomenda não conectar MCP de desenvolvimento a produção e manter aprovação manual de tool calls.

## Claude / Anthropic
- MCP: https://docs.anthropic.com/en/docs/mcp
- Claude Code CLI: https://docs.anthropic.com/en/docs/claude-code/cli-usage
- Agent Skills best practices: https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices

Pontos usados no pacote:
- `CLAUDE.md` e `.claude/settings.json` formam contexto/configuração de projeto.
- Skills usam `SKILL.md` com frontmatter `name` + `description` e divulgação progressiva.
- MCP pode ser configurado no projeto e ferramentas podem ser limitadas por permissões.

## Next.js PWA
- https://nextjs.org/docs/app/guides/progressive-web-apps

Pontos usados:
- App Router suporta `app/manifest.ts`.
- Service worker pode ser registrado pela aplicação.
- HTTPS é requisito de instalação/produção.
- Push usa Web Push + VAPID.
- Offline deve ser implementado/testado explicitamente; Serwist é opção, não obrigação deste projeto.
