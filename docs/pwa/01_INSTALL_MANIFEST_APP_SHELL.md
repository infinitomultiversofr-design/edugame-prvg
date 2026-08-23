# PWA 01 — Instalação, manifest e app shell

## Manifest
Implementar em `app/manifest.ts` com:
- `name`: EduGame PRVG (branding futuramente por escola sem expor organização errada em cache).
- `short_name`: EduGame.
- `start_url`: rota de entrada estável.
- `display`: `standalone`.
- `background_color` e `theme_color` alinhados aos tokens escuros.
- ícones 192x192 e 512x512; incluir ícone maskable quando disponível.
- `lang`: `pt-BR`.

Não incluir IDs sensíveis no `start_url`.

## App shell
Shell mínimo cacheável:
- CSS/tokens essenciais.
- logo/ícones próprios.
- layout de entrada.
- tela offline.
- fontes somente se licenciadas e servidas de modo previsível.

Não precachear vídeos, bestiário completo, 200 animais ou bundles de jogos no primeiro carregamento.

## Registro do SW
Registrar somente no cliente e somente em produção/staging PWA habilitado. Desenvolvimento pode oferecer flag explícita para testes de SW.

## Instalação
- HTTPS obrigatório fora de localhost.
- Não depender de `beforeinstallprompt`; Safari/iOS tem fluxo próprio.
- Exibir instruções de instalação apenas quando aplicável.
- Nunca bloquear uso web porque o app não foi instalado.

## Atualizações
A versão do shell deve ser exibível em diagnóstico técnico. Se houver nova versão, oferecer recarregamento seguro e evitar auto-reload no meio de quiz/tarefa não sincronizada.
