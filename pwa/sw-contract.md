# Contrato do Service Worker

O SW pode: servir shell offline, assets versionados, mídia explicitamente baixada, receber push, informar update e participar do disparo de sync.

O SW não pode: decidir pontos/acertos/recompensas, armazenar service_role, expor resposta de API privada em cache genérico, ignorar RLS, ou transformar Background Sync em autoridade.

Mensagens cliente↔SW previstas: `CHECK_VERSION`, `UPDATE_AVAILABLE`, `SKIP_WAITING_WHEN_SAFE`, `SYNC_REQUESTED`, `SYNC_STATUS`, `PURGE_USER_SCOPE`.
