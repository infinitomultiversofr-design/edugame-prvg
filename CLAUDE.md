# CLAUDE.md — EduGame PRVG

Este arquivo governa Claude Code/Claude Desktop quando trabalhar nesta pasta.

## Bootstrap obrigatório
1. Leia `START_HERE.md`.
2. Leia `docs/00_DOCUMENTATION_INDEX.md`.
3. Leia `EDUGAME_CODEX_MASTER_SPEC.md` e `ROADMAP_M0_M11.md`.
4. Identifique o marco/ticket e leia o gate correspondente.
5. Carregue apenas os documentos/Skills necessários à tarefa.

## Estado do projeto
- M0-A precisa ser executado e validado em Supabase dev/staging isolado.
- Não iniciar M1 antes do Gate M0 Final.
- O pacote contém especificações M0–M11; presença de documentação futura não autoriza implementação antecipada.

## MCP Supabase
- `.mcp.json` é **read-only + project-scoped** por padrão.
- Defina `SUPABASE_PROJECT_REF` localmente; nunca versionar credenciais.
- Para escrita em dev/staging, use `.mcp.write.example.json` somente durante ticket autorizado e mantenha aprovação manual.
- Nunca usar MCP de desenvolvimento contra produção.

## Skills locais
- `edugame-orchestrating`: ordem, gates, DoD.
- `edugame-supabase`: migrations/RLS/Auth/MCP.
- `edugame-security`: LGPD, autorização e menores.
- `edugame-pwa`: PWA/offline/sync/push/performance.
- `edugame-testing`: testes e evidências.
- `edugame-ui`: design system/referências/a11y.
- `edugame-arena`: Arcade/Arena/realtime.

## Regras inegociáveis
- não reescrever arquitetura aprovada sem ADR;
- não avançar de marco sem Gate;
- não implementar módulos fora do ticket;
- nunca confiar no cliente para acerto, pontuação, desbloqueio, autorização ou identidade de terceiros;
- preservar multi-escola, UUID, RLS, auditoria, idempotência e três ledgers independentes;
- responsável permanece somente leitura dos estudantes vinculados;
- ranking individual público/disciplinar permanece descartado;
- sem anúncios, loot boxes, dinheiro real, violência ou chat aberto entre menores;
- estética original e escura; imagens em `reference-ui/` são referência, não background clicável;
- build, lint, typecheck e testes relevantes ao terminar.

## PWA
Leia `docs/pwa/00_PWA_MASTER_SPEC.md`. A PWA é offline-capable, não offline-authoritative. Quiz oficial/pontos/recompensas dependem do servidor; cache local nunca amplia acesso.

## Encerramento de tarefa
Informe arquivos alterados, testes executados, evidência do gate, riscos remanescentes e qual próximo ticket está liberado. Não declarar “pronto” com mockup ou SQL não aplicado.
