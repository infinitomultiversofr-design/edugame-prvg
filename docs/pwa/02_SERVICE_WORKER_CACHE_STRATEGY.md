# PWA 02 — Service Worker, cache e atualização

## Objetivo
Disponibilidade sem vazamento de dados e sem servir versão incoerente.

## Classes de cache
1. `shell-v{build}` — HTML offline mínimo, CSS, JS crítico, ícones.
2. `static-v{build}` — assets versionados/hashados.
3. `media-v{contentVersion}` — somente mídia explicitamente baixável.
4. `public-content-v{contentVersion}` — bestiário/recursos públicos aprovados.

Não criar cache genérico de API autenticada.

## Estratégias
- assets hashados: Cache First com expiração por versão.
- navegação autenticada: Network First; fallback para shell/estado offline, não snapshot de outro usuário.
- dados pessoais: fetch normal + persistência controlada em IndexedDB quando o domínio permitir.
- mídia baixável: Cache First após opt-in/download concluído, com metadado de licença/versão.
- imagens remotas não confiáveis: não cachear sem política de origem.

## Lifecycle
### install
Precache apenas shell mínimo. Falha em asset opcional não deve impedir instalação.

### activate
- remover caches antigos não referenciados;
- migrar metadata local quando compatível;
- não apagar fila pendente sem política de migração.

### fetch
Interceptar somente rotas explicitamente listadas. Não usar catch-all que armazene respostas privadas.

## Atualização segura
- SW novo entra como waiting quando há cliente ativo.
- UI recebe `update_available`.
- usuário aplica update em ponto seguro.
- se versão exige migração de IndexedDB, executar migração transacional; em falha, preservar dados e mostrar erro recuperável.

## Headers
`/sw.js` deve evitar cache intermediário agressivo e ser servido como JavaScript. CSP do app e do SW deve ser compatível com scripts próprios.
