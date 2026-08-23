# EduGame — Projeto Completo

> Para Claude, ChatGPT Desktop ou Codex, comece por `START_HERE.md`.

# EduGame — Migration Pack M0 Revision 2.2 Hardened

Esta é a revisão executável da Fundação M0.

## Por que 2.2?
A revisão 2.1 estava correta no núcleo de RLS, mas a auditoria de 0001–0007
encontrou quatro bloqueadores — entre eles, uma suíte pgTAP que **nunca
executou** (todos os arquivos abortavam em `plan()`) e vínculos suspensos que
mantinham acesso aos dados do estudante. A migration `0008_authz_hardening.sql`
corrige isso, a suíte foi reescrita (10 arquivos, 140 asserções) e
`scripts/m0-gate.mjs` foi ampliado. O relatório completo está em
`GATE_M0A_EVIDENCE.md`.

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

# testes SQL/pgTAP (10 arquivos, 140 asserções)
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

## Validação sem Supabase
Para iterar em migrations e testes sem gastar um projeto, há um verificador que
aplica um shim mínimo do ambiente Supabase em um PostgreSQL comum:

```bash
PGHOST=/var/run/postgresql PGUSER=postgres ./scripts/m0-local-verify.sh
```

Ele não substitui o Gate: `auth.uid()` e os papéis são reproduzidos, mas
PostgREST e `service_role` da plataforma não.

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
