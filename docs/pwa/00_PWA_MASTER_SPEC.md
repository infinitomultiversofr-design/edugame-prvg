# PWA 00 — Especificação mestre

## 1. Objetivo
O EduGame deve funcionar como PWA instalável e resiliente em celulares/tablets/computadores escolares, inclusive com conexão instável, sem deslocar para o cliente decisões que pertencem ao servidor.

**Princípio:** offline-capable, não offline-authoritative.

## 2. Stack
- Next.js App Router.
- React + TypeScript strict.
- Supabase Auth/Database/Realtime/Storage conforme contratos do projeto.
- Service Worker próprio ou biblioteca equivalente aprovada por ADR; o contrato abaixo independe da biblioteca.
- IndexedDB para estado offline explícito.
- Vitest/RTL/Playwright + testes SQL/RLS.

## 3. Capacidades obrigatórias
1. Manifest válido e instalação quando a plataforma suportar.
2. App shell e assets críticos disponíveis após primeira visita concluída.
3. Página/estado offline explícito.
4. Conteúdos marcados como baixáveis persistem localmente com quota/limpeza.
5. Fila de sincronização idempotente para operações permitidas.
6. Atualização de service worker sem tela presa em versão incompatível.
7. Purga de dados locais no logout/troca de conta/organização.
8. Telemetria de erro/performance/sync sem expor gabaritos ou dados disciplinares.
9. Push opcional e seguro para menores.
10. Modo Low/Normal/Immersive.
11. Acessibilidade de teclado, leitor de tela, contraste e redução de movimento.
12. Testes offline/reconexão em Android, desktop Chromium e Safari/iOS dentro da matriz suportada.

## 4. Autoridade por domínio
- Login: servidor.
- Quiz oficial: servidor; offline mantém no máximo rascunho elegível, nunca confirma acerto/ponto.
- Revisão/vídeo/leitura: progresso local permitido; servidor reconcilia.
- Avatar/Pet: preview local; servidor valida posse/compatibilidade.
- Pontuação/recompensas: servidor exclusivamente.
- Arcade prática offline: permitido sem prêmio oficial.
- Arena: requer rede e servidor realtime.
- Telemetria: fila local limitada e descartável.

## 5. Dados proibidos no cache/fila
- `service_role`, tokens privilegiados, VAPID private key.
- gabarito de quiz oficial antes da resolução autorizada.
- dados de outros usuários/turmas fora do vínculo.
- conteúdo disciplinar/risco destinado apenas à gestão em superfícies de estudante/família.

## 6. Identidade local
Toda store IndexedDB que contenha estado de usuário carrega `user_id`, `organization_id` e `schema_version`. A aplicação nunca reutiliza uma store lógica de outro usuário sem purge/namespace.

## 7. Estados globais de conectividade
`online` | `degraded` | `offline` | `syncing` | `update_available`.

A UI deve refletir estado real; `navigator.onLine` é sinal auxiliar, não prova de acesso ao backend.

## 8. Critério de completo
M9 só fecha quando os cenários de `10_PWA_ACCEPTANCE_TESTS.md` passam e as métricas de performance ficam dentro de `docs/24_PERFORMANCE_BUDGETS.md`.
