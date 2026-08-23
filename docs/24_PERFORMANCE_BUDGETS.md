# 24 — Performance Budgets

## Fluxos críticos
Login, Home, Quiz e lançamento de pontos adulto.

## Alvos
- LCP ≤ 2.5s em cenário de teste definido;
- INP ≤ 200ms;
- CLS ≤ 0.1;
- resposta de ação server-side: medir p50/p95;
- UI nunca espera WebGL para ficar funcional.

## Budgets de revisão
- JS inicial Login/Home > 200 kB gzip: warning e análise;
- imagem individual acima do necessário: falha de pipeline;
- WebGL bundle fora de rota imersiva: falha;
- vídeo no bundle inicial: falha;
- grid de 200 animais sem virtualização/lazy thumbnails: falha.

## Cenários de teste
- 4 GB RAM;
- CPU throttling;
- rede lenta;
- WebGL indisponível;
- reduced motion;
- 360x640;
- 1024x768.
