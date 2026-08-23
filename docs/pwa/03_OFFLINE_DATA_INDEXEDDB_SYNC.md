# PWA 03 — IndexedDB, offline e sincronização

## Stores mínimas
### `meta`
`key`, `value`, `updated_at`.

### `user_snapshots`
`key`, `user_id`, `organization_id`, `kind`, `payload`, `server_version`, `expires_at`, `updated_at`.

### `drafts`
`id`, `user_id`, `organization_id`, `type`, `payload`, `entity_id`, `created_at`, `updated_at`, `expires_at`.

### `sync_queue`
`operation_id`, `user_id`, `organization_id`, `type`, `payload`, `idempotency_key`, `state`, `attempt_count`, `next_retry_at`, `created_at`, `last_error_code`.

### `downloaded_content`
`content_id`, `version`, `user_scope`, `cache_key`, `bytes`, `downloaded_at`, `expires_at`.

## Estados da fila
`pending → sending → acknowledged`

Erros:
`retryable_error → pending` após backoff;
`permanent_error` requer UI/ação do usuário.

## Retry
Backoff exponencial com jitter e teto. Não fazer loop agressivo ao recuperar rede. Respeitar 401/403 como erro de autorização, não como retry infinito.

## Idempotência
Toda mutação que possa ser repetida após reconexão usa `operation_id` UUID e `idempotency_key`. O servidor registra/recusa duplicata sem criar segunda recompensa.

## Reconciliação
- progresso de vídeo/leitura: política monotônica quando fizer sentido (`max(progress)`), com versão servidor.
- Avatar/Pet: servidor valida inventário; rejeição restaura último estado confirmado.
- quiz rascunho: só envia se sessão ainda estiver válida; cliente não envia `is_correct` nem pontos.
- telemetria: batch; pode descartar itens antigos/duplicados.

## Conta e organização
No login, confirme `user_id` + `organization_id` antes de expor snapshots. No logout, apagar snapshots, drafts, downloads privados e fila do usuário; conteúdo público versionado pode permanecer.

## Quota
Antes de download grande, usar Storage Estimate quando disponível. Oferecer “Gerenciar conteúdo offline” e política LRU para conteúdo rebaixável, nunca para fila pendente.
