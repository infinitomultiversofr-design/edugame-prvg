# PWA 09 — Backlog executável do M9

## M9.1 Manifest e instalação
- `app/manifest.ts`.
- ícones/maskable.
- metadados/theme.
- checklist HTTPS/install.

## M9.2 Service Worker mínimo
- registro.
- shell offline.
- cache versionado.
- lifecycle/update channel.

## M9.3 IndexedDB
- schema versionado.
- namespace usuário/organização.
- repositories tipados.
- quota/cleanup.

## M9.4 Sync engine
- queue state machine.
- idempotency.
- retry/backoff.
- auth-aware pause/resume.
- online/degraded detection.

## M9.5 Domínios offline
Implementar um por vez conforme `docs/21_SYNC_MATRIX.md`: vídeo/leitura → Avatar/Pet → telemetria → prática offline. Quiz oficial fica sem recompensa offline.

## M9.6 Push
Somente após aprovação de privacidade e finalidade.

## M9.7 Performance/qualidade adaptativa
Low/Normal/Immersive, lazy de jogos/3D/mídia, budgets.

## M9.8 A11y
Auditoria teclado, leitor, contraste, motion e estados offline.

## M9.9 Observabilidade
Eventos/códigos, painel técnico e alertas de sync/update.

## M9.10 Gate
Passar `10_PWA_ACCEPTANCE_TESTS.md` e anexar evidências ao gate do marco.
