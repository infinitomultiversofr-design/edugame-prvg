# PWA 07 — Observabilidade e analytics

## Eventos permitidos
`screen_view`, `quiz_started`, `quiz_completed`, `review_started`, `review_completed`, `game_session_started`, `game_session_completed`, `avatar_saved`, `resource_started`, `resource_completed`, `pwa_installed`, `offline_entered`, `offline_exited`, `sync_started`, `sync_succeeded`, `sync_failed`, `sw_update_available`, `sw_updated`, `error_code`, `performance_bucket`.

## Não registrar
- gabarito em analytics genérico;
- texto livre sensível;
- tokens;
- ocorrência disciplinar;
- payload integral de fila.

## Métricas PWA
- taxa de instalação (quando mensurável sem fingerprinting);
- sessões offline;
- itens de fila por estado;
- idade p95 da fila;
- taxa de retry/permanent_error;
- versão de SW ativa;
- falhas de update/migração;
- bytes de conteúdo offline;
- LCP/INP/CLS por bucket de aparelho/rede quando permitido.

## Logs
Servidor registra operação idempotente, status e erro estruturado. Cliente registra códigos, não dados brutos. Correlacionar com `operation_id` quando necessário.

## Privacidade
Analytics first-party por padrão. Qualquer ferramenta externa exige revisão de privacidade, retenção e contrato.
