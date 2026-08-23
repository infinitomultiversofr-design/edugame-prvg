# AGENTS.md — Regras obrigatórias para Codex

## 1. Antes de alterar qualquer código
- Leia `EDUGAME_CODEX_MASTER_SPEC.md`.
- Leia o documento específico do módulo.
- Inspecione o repositório existente.
- Não recomece do zero se já houver implementação utilizável.
- Liste dependências e riscos da tarefa.
- Trabalhe em um único marco/recorte vertical por vez.

## 2. Arquitetura canônica
Se o repositório ainda não possuir stack estável, usar:
- Next.js App Router;
- React + TypeScript strict;
- Tailwind CSS;
- componentes próprios do Design System EduGame;
- Supabase Auth/PostgreSQL/Storage/Realtime;
- Vercel;
- Framer Motion para movimento de interface;
- Three.js/React Three Fiber apenas em experiências imersivas e carregado sob demanda;
- PWA progressiva.

Use versões estáveis atuais no momento da implementação e mantenha lockfile.

## 3. Nunca fazer
- nunca confiar em `student_id`, `is_correct`, `points_award`, saldo ou desbloqueio enviados pelo navegador;
- nunca enviar gabarito ao frontend antes do momento pedagógico autorizado;
- nunca calcular saldo oficial só no cliente;
- nunca apagar silenciosamente transações auditáveis;
- nunca hardcodar valor de pontos, Passe Livre, semanas ou regras que devem ser configuráveis;
- nunca usar nome como chave de relacionamento;
- nunca misturar placar individual, de grupo e de turma;
- nunca criar chat livre entre estudantes e desconhecidos;
- nunca usar anúncios, compra real, loot box ou mecânica de aposta;
- nunca criar itens cosméticos que deem vantagem acadêmica;
- nunca expor ocorrência, risco, deficiência, laudo ou motivo disciplinar em ranking;
- nunca adicionar arma/combate como mecânica de jogo do EduGame;
- nunca copiar personagem, interface ou asset protegido de terceiros.

## 4. Segurança
- RLS + RBAC + vínculo de escopo.
- Ações sensíveis via RPC/servidor.
- Toda operação premiável deve ser idempotente.
- Toda transação deve guardar origem e ator.
- Estorno cria nova movimentação vinculada.
- Segredos apenas em variáveis de ambiente.
- Service role nunca no frontend.
- Testar RLS com usuários reais de cada papel.

## 5. Design
- Reutilizar componentes do Design System.
- Não criar cores aleatórias por tela.
- Mobile-first.
- Respeitar `prefers-reduced-motion`.
- Nenhuma ação pode depender apenas de hover.
- WebGL é enriquecimento, nunca requisito para concluir atividade.
- As telas em `reference-ui/` são targets de qualidade e atmosfera.

## 6. Qualidade
Para cada tarefa:
1. implementar;
2. rodar lint;
3. rodar typecheck;
4. rodar testes unitários;
5. rodar testes de integração relevantes;
6. rodar Playwright no fluxo afetado;
7. testar autorização/RLS quando houver dados;
8. registrar alteração no changelog/ADR quando houver decisão estrutural.

## 7. Entrega de cada execução
Responder com:
- resumo do que foi feito;
- arquivos alterados;
- migrações criadas;
- testes executados;
- riscos ou pendências;
- como validar manualmente;
- qual é o próximo recorte vertical.

## 8. Não expandir escopo sozinho
Se uma tarefa pede Quiz, não construir Arena junto.
Se uma tarefa pede Avatar, não remodelar o ledger.
Se encontrar dívida técnica que bloqueia a tarefa, explique e corrija apenas o necessário.


## Operational Readiness v1.1
Leia também `docs/20_OPERATIONAL_READINESS_V1_1.md` e os documentos 21–29 antes de iniciar M0/Sprint 1.
