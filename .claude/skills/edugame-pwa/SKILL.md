---
name: edugame-pwa
description: Implementa e revisa a PWA do EduGame em Next.js App Router: manifest, service worker, cache, IndexedDB, sincronização, offline, push, atualização, performance, acessibilidade e observabilidade. Use em qualquer tarefa do M9 ou de resiliência de conexão.
---
# PWA EduGame

Leia primeiro `docs/pwa/00_PWA_MASTER_SPEC.md`; depois carregue apenas o arquivo especializado necessário.

Princípio central: **offline-capable, não offline-authoritative**.

- Quiz oficial, pontuação, recompensas e elegibilidade permanecem server-authoritative.
- Não cacheie gabaritos, tokens privilegiados ou respostas sensíveis em cache compartilhado.
- Dados locais são particionados por usuário + organização e purgados em logout/troca de conta.
- Cache de shell/assets é versionado; APIs autenticadas usam política explícita, não `CacheFirst` genérico.
- IndexedDB guarda rascunhos/progresso/fila mínima; cada mutação sincronizável usa UUID de operação e idempotency key.
- `SyncManager`/Background Sync é melhoria progressiva, nunca requisito de correção.
- Push é opt-in, não expõe informação disciplinar/pedagógica sensível na tela bloqueada.
- Respeite `prefers-reduced-motion`, budgets e modo Low/Normal/Immersive.

Antes de concluir, execute os cenários de `docs/pwa/10_PWA_ACCEPTANCE_TESTS.md`.
