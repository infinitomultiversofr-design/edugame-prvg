# IndexedDB schema v1

Stores: `meta`, `user_snapshots`, `drafts`, `sync_queue`, `downloaded_content`.

Todo registro privado deve ser particionado por `user_id` e `organization_id`. Migrações de schema são versionadas e testadas com dados de versão anterior.
