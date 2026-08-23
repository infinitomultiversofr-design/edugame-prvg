# 15 — Roadmap de Implementação e Gates

## M0 — Fundação
Entregas:
- repo;
- stack;
- environments;
- Supabase;
- migrations baseline;
- Auth;
- shell;
- design tokens;
- feature flags;
- CI.

Gate:
- build;
- lint;
- typecheck;
- deploy staging;
- login de teste;
- RLS smoke test;
- responsive shell.

## M1 — Vertical Slice de aprendizagem
João 8º ano:
login → quiz → feedback → review → vídeo → microcheck.

Gate:
- server authoritative;
- segunda tentativa;
- idempotência;
- persistência;
- design target;
- Playwright completo;
- outro dispositivo recupera estado.

## M2 — Pontuação e professor operacional
- três ledgers;
- regras;
- lote;
- histórico;
- estorno;
- T01-T06.

Gate:
professor passa uma semana sem planilha e reconciliação bate.

## M3 — Quiz autoral completo
- T07-T09;
- currículo;
- question bank;
- publish;
- relatórios habilidade.

Gate:
uma rodada semanal inteira ocorre no EduGame.

## M4 — Identidade
- Avatar Lab;
- 8 famílias;
- 8 animais piloto;
- inventário;
- Pet;
- coleção.

Gate:
todas as famílias equipam kit padrão e persistem.

## M5 — Missões, grupos, eventos
- grupos;
- missões;
- Passe Livre;
- Sala Especial;
- calendário;
- responsável read-only.

Gate:
uma recompensa coletiva é liberada automaticamente e auditada.

## M6 — Arcade
- 6 engines iniciais;
- content packs;
- session validation.

Gate:
seis jogos funcionam com conteúdo de pelo menos três disciplinas sem duplicar engine.

## M7 — Arena
- rooms;
- realtime;
- quick-chat;
- quatro jogos multiplayer;
- reconnect;
- server scoring.

Gate:
20–30 estudantes em teste concorrente sem divergência de placar.

## M8 — Gestão
- aprendizagem;
- convivência;
- planos;
- regras;
- auditoria;
- relatórios.

Gate:
gestão identifica problema, cria plano e acompanha indicador.

## M9 — PWA/offline/performance
- install;
- low mode;
- practice offline;
- sync;
- accessibility audit.

Gate:
fluxos essenciais em celular simples e conexão instável.

## M10 — Escala de catálogo
24 → 48 → 100 → 200 animais.
Expandir jogos e conteúdo.

## M11 — Multi-escola
- branding;
- isolamento;
- provisionamento;
- admin rede.

Gate:
segunda escola criada sem alteração de código e sem vazamento cruzado.

## Regra de gate
Nenhum milestone passa por “parece pronto”.
Checklist técnico + pedagógico + visual + segurança precisa estar verde.
