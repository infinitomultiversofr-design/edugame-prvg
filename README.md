# EduGame — Projeto Completo

> Para Claude, ChatGPT Desktop ou Codex, comece por `START_HERE.md`.

# EduGame — Migration Pack M0 Revision 2.1 Hardened

Esta é a revisão executável da Fundação M0.

## Por que 2.1?
A proposta Revision 2 estava correta em direção, mas ainda tinha bloqueadores:
- helpers com `search_path=''` usavam tabelas sem schema;
- RLS ainda fazia subqueries que poderiam ficar frágeis;
- `user_profiles` deixaria PII órfã após apagar Auth;
- classe/ano/escola ainda podiam ficar inconsistentes;
- feature flags misturavam UUID e role em `scope_id TEXT`;
- overrides brutos podiam vazar IDs de outros usuários;
- não havia resolver de flag determinístico;
- testes RLS ainda precisavam de asserts reais.

Esta versão corrige esses pontos.

## Ordem

```bash
supabase db reset
# migrations rodam automaticamente no fluxo local
supabase db seed

# testes SQL/pgTAP
supabase test db

# gate com Auth real
cd scripts
npm install
ALLOW_M0_GATE=true \
M0_GATE_ENV=local \
SUPABASE_URL=... \
SUPABASE_ANON_KEY=... \
SUPABASE_SERVICE_ROLE_KEY=... \
npm run m0:gate
```

Adapte os comandos à versão instalada do Supabase CLI.

## Importante
O script `m0-gate.mjs` cria e remove fixtures. Ele se recusa a rodar se:
- `ALLOW_M0_GATE` não for `true`;
- `M0_GATE_ENV` não for `dev`, `staging` ou `local`.

Mesmo assim, use somente banco isolado.

## O que ainda NÃO existe
- Quiz
- ledger de pontos
- Avatar
- Pet
- Arena
- portal professor completo

Isso é intencional. O M0 prova identidade, escopo, RLS, feature rollout e auditoria antes de construir o restante.
