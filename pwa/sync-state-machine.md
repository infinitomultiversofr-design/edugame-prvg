# Sync state machine

`pending -> sending -> acknowledged`

Falhas transitórias: `sending -> retryable_error -> pending`.
Falhas permanentes: `sending -> permanent_error`.
401/403: pausar fila e exigir auth; não retry cego.

Cada operação tem UUID + idempotency key; servidor é autoridade final.
