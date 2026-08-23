# PWA 08 — Testes, release e incidentes

## Pirâmide
- unit: política de cache, fila, retry, reducers/estado.
- integration: IndexedDB + auth namespace + reconciliação.
- E2E: Playwright com rede offline/latência/erro.
- device: Android Chromium, desktop Chromium e Safari/iOS suportado.

## Release
1. build/typecheck/lint/test.
2. validar manifest/ícones/HTTPS.
3. validar SW em staging limpo e com versão anterior aberta.
4. simular update com fila pendente.
5. simular logout/troca de conta.
6. simular backend indisponível.
7. publicar canário/staging.
8. monitorar erros de sync/update.
9. rollout progressivo quando infraestrutura permitir.

## Rollback
Rollback de aplicação não pode deixar SW incompatível. Manter compatibilidade de API por janela definida ou invalidar/atualizar SW de modo controlado.

## Incidentes
### Vazamento local entre contas
Severidade alta: desabilitar offline afetado via feature flag, corrigir namespace/purge, forçar atualização, investigar escopo e registrar incidente.

### Fila duplicando operação
Desabilitar replay do tipo, usar idempotência server-side, reconciliar ledger por auditoria; nunca apagar transações silenciosamente.

### SW preso/loop de update
Fornecer rota de recuperação, unregister controlado apenas quando necessário e preservar dados de fila antes de reset.
