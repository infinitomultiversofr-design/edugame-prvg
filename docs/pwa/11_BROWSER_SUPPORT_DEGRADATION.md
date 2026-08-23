# PWA 11 — Compatibilidade e degradação progressiva

## Política
O EduGame não presume suporte uniforme a instalação, Background Sync, push ou quotas. A aplicação web básica e os fluxos online críticos devem continuar funcionando em navegador moderno suportado pelo Next.js.

## Capacidades por detecção
- Service Worker: feature detect.
- Install prompt: não depender dele.
- PushManager: esconder recurso quando indisponível.
- Background Sync: opcional; fallback por eventos online/foco/abertura.
- Storage Estimate/Persistence: usar quando disponível.

## iOS/Safari
Tratar instalação e permissões como fluxo próprio. Não prometer experiência idêntica à de Chromium. Testar navegação standalone, storage eviction, push quando suportado e retomada após suspensão.

## Navegador embutido/WebView
Não assumir instalação/PWA completa. Oferecer experiência web responsiva e mensagem de limitação somente quando um recurso realmente for necessário.

## Critério
Falta de API avançada deve reduzir conveniência, nunca segurança, integridade de pontuação ou autorização.
