---
name: edugame-testing
description: Valida gates, testes automatizados e evidências do EduGame com Vitest, React Testing Library, Playwright e SQL/RLS. Use ao terminar tickets, preparar gate, corrigir regressões ou revisar Definition of Done.
---
# Testes e Gates

1. Descubra o gate vigente e os critérios de aceite.
2. Rode primeiro testes focados; depois suíte ampliada quando a mudança afetar contratos compartilhados.
3. Banco/Auth: testes SQL/RLS com usuários reais de teste e isolamento entre organizações.
4. UI: estados loading/empty/error/offline, teclado, foco e redução de movimento.
5. PWA: instalar, offline, atualização de SW, limpeza de cache por conta, replay idempotente e reconexão.
6. Multiplayer: reconexão, autoridade do servidor, duplicidade, abandono e abuso de quick-chat.
7. Só marque gate como aprovado com evidência reproduzível; nunca por inspeção visual isolada.
