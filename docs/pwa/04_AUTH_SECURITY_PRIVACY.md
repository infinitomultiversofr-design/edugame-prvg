# PWA 04 — Auth, segurança e privacidade

## Sessão
A PWA pode reabrir com sessão Supabase válida conforme o SDK, mas nenhuma autorização é inferida de cache local. Toda operação privilegiada continua passando por RLS/RPC server-side.

## Tokens
- não copiar tokens para Cache Storage.
- não serializar token em fila de sync.
- não registrar token em logs/analytics.
- service worker não deve inventar mecanismo paralelo de autenticação.

## Dados de menores
Offline deve reduzir dados, não espelhar o banco inteiro. Snapshot de estudante contém apenas o necessário para a tela offline autorizada.

## Logout/troca de conta
1. bloquear novas leituras privadas;
2. cancelar/pausar sync;
3. apagar IndexedDB privada do namespace;
4. apagar caches privados, se existirem;
5. concluir sign-out;
6. voltar à tela neutra.

## Dispositivo compartilhado
Assumir que computador/tablet escolar pode ser compartilhado. Não mostrar nome, pontuação, risco ou histórico anterior antes de autenticação válida. Não manter notificações locais com conteúdo sensível após logout.

## XSS/CSP
Service worker amplia persistência de código; CSP, dependências e scripts externos precisam de revisão. Não usar `eval`/script remoto arbitrário para jogos/conteúdo.

## Push e tela bloqueada
Payload nunca contém ocorrência disciplinar, nota detalhada, diagnóstico de risco ou informação que exponha o estudante a terceiros. Preferir texto neutro (“Você tem uma atividade nova no EduGame”).

## Ameaças específicas
- cache poisoning;
- usuário A vendo snapshot do B;
- replay duplicando recompensa;
- fila adulterada enviando pontos;
- SW antigo chamando API incompatível;
- mídia de terceiro persistida sem licença.

Cada ameaça possui teste em `10_PWA_ACCEPTANCE_TESTS.md`.
