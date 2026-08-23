# 13 — PWA, Performance, Conectividade e Observabilidade

Este documento continua sendo a visão transversal; a especificação completa e executável está em `docs/pwa/`.

## Princípio
O EduGame é **offline-capable, não offline-authoritative**. Pontuação, gabarito, recompensas, elegibilidade, inventário oficial e autorização permanecem server-side.

## Capacidades
- manifest/instalação;
- service worker e app shell;
- cache explícito/versionado;
- IndexedDB com namespace usuário + organização;
- fila idempotente com retry/backoff;
- atualização segura do SW;
- conteúdo offline autorizado;
- push opt-in e neutro;
- Low/Normal/Immersive;
- acessibilidade e `prefers-reduced-motion`;
- telemetria first-party e diagnóstico de sync.

## Offline permitido
Dashboard/snapshot autorizado, bestiário/coleção, materiais previamente baixados, progresso de leitura/vídeo, preview Avatar/Pet, prática não pontuada e jogos solo permitidos.

## Offline não autoritativo
Quiz oficial não confirma acerto/ponto sem servidor. Arena multiplayer exige rede. Cliente nunca envia decisão de prêmio.

## Documentação executável
Comece por `docs/pwa/00_PWA_MASTER_SPEC.md` e use `docs/pwa/10_PWA_ACCEPTANCE_TESTS.md` para o gate M9.

## Performance e observabilidade
Budgets numéricos: `docs/24_PERFORMANCE_BUDGETS.md`.
Eventos/logs: `docs/pwa/07_OBSERVABILITY_ANALYTICS.md`.
Operação/release: `docs/pwa/08_TESTING_RELEASE_INCIDENTS.md`.
