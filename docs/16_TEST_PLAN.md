# 16 — Plano de Testes

## Pirâmide
- unit;
- integration;
- database;
- RLS/security;
- e2e;
- visual regression em telas críticas;
- load/realtime;
- accessibility.

## Auth
- ID/PIN válido;
- inválido;
- rate limit;
- estudante bloqueado;
- sessão revogada;
- dispositivo compartilhado;
- role routing.

## Quiz
- fechado;
- fora da turma;
- primeira correta;
- primeira errada;
- segunda correta;
- duas erradas;
- terceira rejeitada;
- opção inválida;
- clique duplo;
- refresh;
- reconexão;
- conclusão duplicada;
- gabarito indisponível no client network payload.

## Scoring
- individual;
- grupo;
- turma;
- source_key duplicada;
- estorno;
- regra expirada;
- ator sem escopo;
- lote parcial deve falhar atomicamente ou reportar claramente conforme contrato.

## Avatar
- item sem posse;
- item inativo;
- variante familiar;
- fallback;
- espécie de cada família;
- save/load;
- XSS nome;
- moderação.

## Arena
- room full;
- wrong class;
- expired code;
- duplicate join;
- latency;
- disconnect/rejoin;
- simultaneous answers;
- cheating replay;
- finish once;
- points cap.

## RLS matrix
Criar fixtures para cada papel e afirmar SELECT/INSERT/UPDATE/DELETE permitido/proibido.

## A11y
- axe;
- keyboard;
- screen reader smoke;
- contrast;
- reduced motion;
- 200% text;
- captions.

## Performance
- low-end emulation;
- slow network;
- WebGL disabled;
- large inventory;
- 250 concurrent auth/read scenario;
- realtime room concurrency compatível com piloto.

## Migração
- contagem fonte/destino;
- checksums;
- duplicate identity;
- rollback strategy;
- audit.
