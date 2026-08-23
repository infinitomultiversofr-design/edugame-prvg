# PWA 06 — Performance, acessibilidade e qualidade adaptativa

## Prioridade
O app precisa funcionar em computador escolar simples e celular intermediário, com rede instável.

## Budgets
Usar `docs/24_PERFORMANCE_BUDGETS.md` como números canônicos. O M9 não pode aumentar bundle inicial para carregar jogos, WebGL, vídeo ou 200 animais.

## Estratégias
- code splitting por rota/engine.
- `next/image`/assets responsivos quando aplicável.
- AVIF/WebP com fallback.
- vídeo nunca no critical path.
- prefetch seletivo; não desperdiçar dados móveis.
- virtualização de grades grandes.
- fontes mínimas e `font-display` apropriado.

## Modos
### Low
Sem blur caro, partículas, vídeo decorativo, WebGL, sombras pesadas; animações mínimas.

### Normal
Padrão equilibrado.

### Immersive
Efeitos extras somente em aparelho/rede adequados e com opt-in/heurística reversível.

## A11y
- WCAG aplicável ao contexto escolar.
- foco visível e ordem lógica.
- todas as ações por teclado.
- labels/roles corretos.
- feedback de erro não depende só de cor/som.
- legenda/transcrição para mídia pedagógica quando disponível.
- `prefers-reduced-motion` desliga animações não essenciais.
- jogos têm alternativa acessível quando a mecânica permitir.

## Offline UX
Badge claro “Offline”/“Sincronizando”. Nunca mostrar ponto ganho antes da confirmação server-side.
