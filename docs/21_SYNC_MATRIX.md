# 21 — Sync Matrix

| Domínio | Pode operar offline? | Pode premiar offline? | Persistência local | Reconciliação |
|---|---|---:|---|---|
| Login | não | não | sessão já existente conforme SDK | servidor |
| Quiz oficial | rascunho/local limitado | não | estado UI/IndexedDB | RPC idempotente |
| Revisão | sim parcialmente | não automaticamente | IndexedDB | servidor |
| Vídeo | sim se asset permitido | não | progresso local | max/progresso reconciliado |
| Avatar | preview sim | não | IndexedDB | servidor valida inventário |
| Pet | preview sim | não | IndexedDB | servidor |
| Arcade prática | sim | não | local | estatística opcional |
| Arena | não | sim conforme regra | nenhum placar oficial local | servidor realtime |
| Notificações | leitura cacheada | n/a | cache | servidor |
| Telemetria | sim | n/a | fila limitada | batch |

## Estados de fila
pending → sending → acknowledged | retryable_error | permanent_error

Cada item tem:
- operation_id UUID;
- type;
- payload mínimo;
- created_at;
- attempt_count;
- next_retry_at.

Segredos, gabaritos e tokens privilegiados nunca entram na fila.
