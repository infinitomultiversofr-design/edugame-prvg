# EDUGAME — ESPECIFICAÇÃO MESTRE PARA CODEX

## 0. Visão

EduGame é uma plataforma escolar web/PWA que une aprendizagem, gamificação, convivência, identidade digital, jogos educacionais, missões, recompensas, eventos e gestão pedagógica.

Não é um simples ranking.
Não é um portal escolar tradicional.
Não é um catálogo de minijogos desconectados.

A experiência deve parecer um **universo de videogame educacional premium**, porém cada elemento visual precisa conduzir a uma ação pedagógica, de colaboração, pertencimento ou gestão.

### Escola piloto
EMEFTI Paulo Roberto Vieira Gomes — Vitória/ES.

### Público
- estudantes do 1º ao 8º ano no piloto;
- estrutura preparada para 9º ano;
- professores;
- pedagogia/coordenação;
- direção;
- responsáveis;
- administração escolar;
- administração de rede no futuro.

### Escala-alvo inicial
- 250+ estudantes cadastrados;
- uso concorrente em ambiente escolar;
- arquitetura multi-escola;
- nenhuma tabela ou regra desenhada como “escola única para sempre”.

---

## 1. Resultado que define sucesso

O sistema é considerado completo quando:
- um estudante entra, aprende, joga, personaliza e encontra histórico persistente;
- um professor conduz a rotina sem planilha paralela;
- um responsável vê apenas os estudantes vinculados;
- gestão transforma dados em ação registrada;
- admin abre novo ano preservando histórico;
- três placares continuam independentes;
- quizzes, jogos, vídeos, Avatar Lab, Pet, eventos e recompensas são reais e moderáveis;
- dispositivos simples continuam capazes de usar funções essenciais;
- conexão instável não causa duplicação ou perda silenciosa;
- backups, auditoria, estornos, testes e observabilidade existem;
- outra escola entra sem alteração estrutural do código.

---

## 2. Pilares

### Pedagogia
Conteúdo ligado a currículo, habilidade e objetivo de aprendizagem.

### Ciência do comportamento
Medir início, persistência, recuperação e autonomia sem criar punição psicológica ou dependência.

### Gamificação
Narrativa, progresso, personalização, jogos e recompensas como veículo de aprendizagem.

### Segurança escolar
Dados de menores, convivência, autorizações, auditoria e moderação são requisitos de produto.

---

## 3. Princípios inegociáveis

1. Aprendizagem antes da competição.
2. Placar individual, grupo e turma são livros-razão lógicos separados.
3. Regras são versionadas por escola/ano/período.
4. Toda movimentação oficial é auditável.
5. Correção é estorno, não exclusão.
6. Dados sensíveis nunca aparecem em ranking.
7. Responsável é somente leitura.
8. Cosméticos não dão vantagem.
9. Pontos não são comprados nem vendidos.
10. Pontos desbloqueiam; o estudante não precisa “gastar” saldo.
11. Sem anúncios e sem rastreamento publicitário.
12. Sem loot boxes.
13. Sem chat aberto com desconhecidos.
14. Sem armas e violência como jogo.
15. Conteúdo gerado por IA exige revisão humana antes de publicação.
16. O navegador nunca é autoridade sobre pontuação ou acerto.
17. Interface funcional sem WebGL.
18. Acessibilidade WCAG 2.2 AA como referência.
19. Originalidade visual e autoral.
20. Toda expansão deve preservar isolamento multi-escola.

---

## 4. Stack canônica

### Aplicação
Next.js App Router + React + TypeScript strict.

### UI
Tailwind + Design System EduGame.
Primitivos externos podem ser usados, mas a aparência final deve ser original.

### Backend
Supabase:
- PostgreSQL;
- Auth;
- Storage;
- Realtime;
- Edge Functions quando realmente necessário.

### Segurança
- RLS;
- RPCs SECURITY DEFINER cuidadosamente limitadas;
- validação server-side;
- idempotência.

### Animação
- CSS/Framer Motion para interface;
- Three.js/R3F para experiências imersivas sob demanda;
- modo gráfico low/normal/immersive.

### Deploy
Vercel para aplicação.
Ambientes separados: dev, staging, production.

### Testes
Vitest + React Testing Library + Playwright + testes SQL/RLS.

---

## 5. Organização do repositório

```text
src/
  app/
    (public)/
    student/
    teacher/
    family/
    manage/
    network/
  features/
    auth/
    dashboard/
    learning/
    quiz/
    review/
    video/
    missions/
    scoring/
    games/
    arena/
    avatar/
    pet/
    rewards/
    events/
    community/
    behavior/
    reports/
    admin/
  components/
    ui/
    edugame/
  design-system/
    tokens/
    motion/
    icons/
  domain/
  services/
  lib/
  hooks/
  types/
supabase/
  migrations/
  tests/
  seed/
public/
  assets/
  offline/
docs/
tests/
```

Não organizar o projeto por “páginas gigantes”. Cada domínio precisa conter UI, estado, contratos e testes relacionados.

---

## 6. Navegação macro

### Estudante
Início · Aprender · Jogar · Comunidade · Perfil.

### Professor
Dashboard · Turmas · Pontos · Aprendizagem · Conteúdo · Missões · Convivência · Eventos · Relatórios.

### Família
Resumo · Aprendizagem · Histórico · Recompensas · Pergunta da semana · Eventos.

### Gestão
Executivo · Turmas · Aprendizagem · Convivência · Planos · Regras · Conteúdo · Pessoas · Auditoria.

---

## 7. Primeira fatia vertical obrigatória

Antes de Avatar Lab, multiplayer ou gestão completa, construir e aprovar:

Login → Home → Quiz → Acerto → Explicação do acerto → Erro → Dica → Segunda tentativa → Erro final → Resolução → Conclusão → Revisão inteligente → Vídeo → Microquestão → Habilidade recuperada → Persistência.

Este fluxo deve usar dados reais, RLS real e RPC real.

As telas do fluxo já possuem referências em `reference-ui/quiz/`.

---

## 8. Critério de engenharia

Uma tela não está pronta quando “parece com o mockup”.
Está pronta quando:
- dados reais;
- loading;
- empty state;
- erro;
- autorização;
- responsividade;
- teclado;
- leitor de tela;
- reconexão;
- analytics first-party mínimo;
- testes;
- performance;
- persistência;
- auditoria quando aplicável;
- visual próximo ao target.

---

## 9. Expansão

Depois do núcleo:
1. Identidade — Avatar + Pet + Coleção.
2. Mundo — missões, ilhas, calendário, eventos.
3. Arcade individual.
4. Arena multiplayer.
5. Recompensas e temporadas.
6. Professor.
7. Família.
8. Gestão/Admin.
9. Inteligência e recomendações.
10. 200 animais e expansão multi-escola.

Os módulos posteriores devem ser previstos no modelo de dados desde o início, mas não todos implementados de uma vez.

---

# V1.1 — DETALHAMENTO OPERACIONAL OBRIGATÓRIO

> Esta seção integra as lacunas operacionais identificadas após a versão 1.0.
> Em caso de conflito com uma frase anterior, prevalecem as invariantes de segurança,
> auditoria, multi-escola e server-authoritative descritas nesta V1.1.

## 10. Modelo Conceitual de Dados — invariantes antes das cardinalidades

O modelo operacional não deve representar papéis como uma única coluna `users.role`.
Uma mesma pessoa pode acumular papéis em contextos diferentes. O vínculo correto é:

- `auth.users` → identidade de autenticação;
- `user_profiles` → dados de perfil;
- `school_memberships` → usuário + escola + papel + status;
- `teacher_assignments` → professor + turma + componente;
- `guardian_student_links` → responsável + estudante;
- `students` → identidade escolar do estudante;
- `enrollments` → estudante + turma + ano letivo.

Currículo e conteúdo:
- `curriculum_frameworks`;
- `curriculum_skills`;
- `questions` + `question_options`;
- `quizzes` + `quiz_questions`;
- `learning_resources`;
- `micro_checks`;
- workflow/versionamento de conteúdo.

Tentativas:
- são registradas pelo servidor;
- possuem chave de idempotência nas operações premiáveis;
- o cliente nunca envia `is_correct` ou `points_award`.

Pontuação:
- usar `score_transactions` como ledger imutável;
- não atualizar saldo via `UPDATE`;
- três escopos independentes: estudante, grupo, turma;
- transações guardam regra, ator, origem, `source_key` e `reversal_of`.

Inventário:
- `student_inventory` representa posse;
- desbloqueios são avaliados pelo servidor;
- cosméticos não alteram vantagem acadêmica.

## 11. Estratégia de Sincronização e Resiliência — Sync Matrix

O EduGame é **offline-capable**, não offline-authoritative.

| Ação | Sem rede | Sincronização | Autoridade |
|---|---|---|---|
| Quiz oficial pontuado | não confirma envio; sessão permanece utilizável quando possível e a UI informa que é necessário reconectar para validar | retry após reconexão com idempotency key | servidor |
| Resposta já escolhida em tela | pode permanecer apenas como rascunho local não enviado | envia após reconexão somente se a sessão ainda for válida | servidor |
| Progresso de vídeo/leitura | IndexedDB | fila FIFO + retry | servidor reconcilia |
| Avatar/Pet | preview local permitido | fila eventual; servidor valida posse/compatibilidade | servidor |
| Telemetria não crítica | fila local limitada | envio em lote; eventos antigos podem ser descartados | servidor |
| Prática offline não pontuada | funciona localmente | pode enviar estatística resumida depois | sem recompensa oficial |

`SyncManager` não é dependência obrigatória. Usar Service Worker + fila manual e
fallback de reconexão. Não prometer um “polyfill total” para semântica de Background Sync.

## 12. Lifecycle de Conteúdo e Moderação

Estados canônicos:

`draft → pedagogical_review → approved/published → archived`

Reprovação:
`pedagogical_review → rejected`

Regras:
- editar conteúdo publicado gera nova versão draft;
- a versão publicada anterior permanece ativa até promoção atômica da nova;
- guardar `version_of`, `reviewed_by`, `reviewed_at`, `review_notes`;
- conteúdo gerado por IA entra sempre como draft;
- publicação exige revisão humana conforme política do conteúdo.

## 13. Política de Retenção, Privacidade e Direitos do Titular

A aplicação **não hardcoda prazos jurídicos universais**.

A política de retenção é configurada por:
- categoria de dado;
- finalidade;
- base legal adotada pela instituição;
- obrigação educacional/administrativa aplicável;
- tabela de temporalidade da rede/município;
- evento de início de retenção;
- prazo;
- ação ao final do prazo.

Categorias mínimas:
- cadastro;
- matrícula;
- aprendizagem/desempenho;
- ledger gamificado;
- convivência;
- responsável/vínculo;
- consentimentos;
- logs/auditoria;
- arquivos/Uploads;
- preferências/telemetria.

Pseudonimização não equivale automaticamente a anonimização.
Hash previsível de nome/ID não deve ser tratado como dado anônimo.

O procedimento de direitos do titular deve suportar, conforme política institucional:
- confirmação;
- acesso;
- correção;
- portabilidade aplicável;
- bloqueio;
- anonimização;
- eliminação quando legalmente permitida.

Nenhum RPC de eliminação deve apagar dados cuja conservação seja obrigatória.
A matriz definitiva de retenção precisa ser aprovada institucionalmente antes de produção.

## 14. Performance Budget e Baseline

Baseline:
- navegadores evergreen efetivamente usados na escola;
- duas versões principais recentes de Chrome, Edge, Firefox e Safari como referência;
- feature detection + progressive enhancement.

Perfis:
- mobile mínimo: 360×640, 4 GB RAM, modo Low;
- desktop escolar mínimo: 1024×768;
- gestão recomendado: ≥1280×720.

Metas de experiência:
- LCP alvo ≤ 2,5 s;
- INP alvo ≤ 200 ms;
- CLS alvo ≤ 0,1.

JS inicial:
- 200 kB gzip é alerta de revisão para Login/Home;
- não é limite absoluto que justifique arquitetura pior.

WebGL:
- lazy;
- opcional;
- nunca requisito para responder quiz, lançar ponto ou consultar dado.

## 15. Feature Rollout e Flags

Hierarquia de resolução:
1. default global;
2. escola;
3. turma;
4. papel;
5. usuário.

Uso:
- rollout seguro;
- piloto;
- kill switch;
- configuração pedagógica.

Não usar experimentação comportamental com crianças como objetivo de conversão.

Toda mudança de flag registra:
- ator;
- data;
- justificativa;
- valor anterior;
- novo valor;
- escopo.

## 16. Contrato de Erros e Experiência de Falha

Backend retorna códigos estáveis, não mensagens de banco para o usuário.

Códigos de domínio:
- `AUTH_REQUIRED`
- `FORBIDDEN_SCOPE`
- `QUIZ_CLOSED`
- `QUIZ_NOT_ASSIGNED`
- `QUESTION_NOT_IN_QUIZ`
- `ATTEMPT_LIMIT`
- `INVALID_OPTION`
- `DUPLICATE_OPERATION`
- `NETWORK_UNAVAILABLE`
- `ITEM_NOT_OWNED`
- `ITEM_INCOMPATIBLE`
- `ROOM_FULL`
- `ROOM_CLOSED`
- `RATE_LIMITED`
- `INTERNAL_ERROR`

UI mapeia para mensagem pt-BR acessível.

Exemplos:
- `FORBIDDEN_SCOPE` → “Você não tem acesso a esta área. Peça ajuda ao seu professor.”
- `QUIZ_CLOSED` → “Este quiz não está disponível agora.”
- `NETWORK_UNAVAILABLE` → “A conexão caiu. Seu progresso local foi preservado quando possível. Vamos tentar novamente.”
- `DUPLICATE_OPERATION` → “Esta ação já foi registrada.”

Stack trace, SQL, RLS e detalhes internos ficam apenas em logs seguros.

## 17. Importação e Migração de Dados Legados

Domínios não se misturam:
- nota acadêmica ≠ ponto gamificado;
- frequência ≠ ponto;
- ocorrência ≠ ranking.

Suporte:
- estudantes;
- responsáveis;
- turmas;
- matrículas;
- histórico de quiz;
- transações legadas do próprio EduGame quando existirem;
- notas acadêmicas apenas em módulo próprio, se habilitado.

Transação histórica do EduGame importada deve ser marcada:
- `origin_type = legacy_import`;
- batch/import_run;
- hash do arquivo;
- linha de origem;
- imported_by;
- data.

Importação não pode “inventar” eventos de jogo que nunca existiram.

## 18. Design System e Tokens Implementáveis

Escala de espaço:
`4, 8, 12, 16, 24, 32, 48, 64`

Radius:
`4, 8, 12, 16, 24`

Movimento:
- hover/focus: 150 ms;
- componente: 180–240 ms;
- transição de tela: 300 ms;
- conquista: até 500 ms;
- reduced motion: remover efeitos não essenciais.

Contraste:
- WCAG 2.2 AA;
- não depender apenas de glow/cor para estado.

Tokens completos ficam em `docs/28_DESIGN_TOKENS_IMPLEMENTABLE.md`.

## 19. Rollback, Estorno e Disaster Recovery

### Estorno lógico
Erro operacional de pontuação não restaura banco.

Criar:
- `reverse_score_transaction`
- `reverse_score_batch`

Estorno:
- cria nova transação;
- aponta para a origem;
- requer motivo;
- é auditado;
- recalcula projeções/snapshots.

### Disaster Recovery
Usar RPO/RTO como objetivos operacionais, não promessa automática.

Alvo inicial:
- RPO ≤ 24 h somente quando rotina de backup diário estiver comprovadamente ativa;
- RTO ≤ 4 h como objetivo operacional de piloto, validado por exercício de restauração.

Banco e Storage precisam de estratégia própria.
Backup do banco não deve ser considerado backup de objetos do Storage.

PITR pode ser habilitado conforme plano/custo/requisito.
A equipe deve realizar restore drill antes de declarar o DR “pronto”.
