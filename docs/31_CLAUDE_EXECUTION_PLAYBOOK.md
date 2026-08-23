# 31 — Playbook de execução no Claude

## Primeira sessão
1. Abra a pasta `EduGame/`.
2. Configure `SUPABASE_PROJECT_REF` para projeto dev/staging.
3. Inicie Claude Code.
4. Autentique o MCP Supabase em `/mcp`.
5. Envie: “Leia START_HERE.md e CLAUDE.md. Informe o marco atual, gates pendentes e não faça alterações.”
6. Só depois entregue um ticket específico.

## Sessão normal por ticket
1. Estado atual (`git status`, gate, ticket).
2. Documentos canônicos do domínio.
3. Inspeção do código e do Supabase real via MCP quando necessário.
4. Plano curto e lista de arquivos a alterar.
5. Implementação mínima do ticket.
6. Testes focados.
7. Build/typecheck/lint.
8. Segurança/RLS quando aplicável.
9. Atualizar docs/changelog somente se contrato mudou.
10. Relatório final: alterações, testes, evidências, riscos, próximo ticket permitido.

## M0
O Gate M0-A não é aprovado por existência de SQL. É necessário executar migrations/seed em ambiente isolado e rodar testes RLS com Auth real. M0-B vem depois; M1 só depois do Gate M0 Final.

## Regra de banco
Antes de aplicar migration, Claude deve listar migrations existentes via MCP e comparar com `supabase/migrations/`. Se houver divergência, parar e explicar; não “corrigir” apagando histórico.

## Regra de produto
Não criar funcionalidade de marco futuro para “adiantar”. Pode preparar interfaces/contratos somente quando o ticket atual exigir e sem expor funcionalidade ativa.

## Regra de PWA
M9 é o marco de fechamento da resiliência PWA, mas decisões de código anteriores devem ser compatíveis com ele: sem dependência de memória efêmera para ações críticas, RPC idempotente, payload mínimo e rotas que possam degradar corretamente.
