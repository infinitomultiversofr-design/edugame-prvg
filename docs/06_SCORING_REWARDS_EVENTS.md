# 06 — Pontuação, XP, Recompensas e Eventos

## Ledger
A fonte da verdade é uma cadeia de transações.

Cada transação:
- id;
- school_id;
- academic_year_id;
- ledger_type: student | group | class;
- target_id;
- amount;
- rule_id;
- origin_type;
- origin_id;
- subject_id opcional;
- reason;
- actor_user_id;
- source_key idempotente;
- reversal_of opcional;
- created_at.

Nunca editar uma transação confirmada.

## Saldo
Pode existir projeção/materialized view para velocidade, mas precisa ser reconciliável com o ledger.

## Regras
`scoring_rules` versionadas:
- escopo;
- valor padrão;
- mínimo/máximo;
- periodicidade;
- disciplina;
- justificativa obrigatória;
- bloqueadores;
- datas de vigência;
- quem pode aplicar.

## XP
Ledger ou eventos positivos separados.
XP:
- nunca negativo;
- não define recompensa escolar oficial sozinho;
- dá nível visual e evolução do Pet quando configurado.

## Anti-abuso
- source_key única;
- limite de repetição;
- jogos não podem gerar pontos infinitos por replay;
- ações offline sincronizam com idempotency key;
- servidor valida sessão.

## Passe Livre
Motor de elegibilidade:
- regra por período;
- pontuação mínima;
- bloqueadores autorizados;
- participação opcional;
- snapshots auditáveis.

UI explica:
- conquistado;
- falta X;
- bloqueado por regra sem expor informação inadequada;
- data de reavaliação.

## Sala Especial
- classificação por etapa;
- regras configuráveis;
- partida/evento;
- turmas participantes;
- jogo;
- resultado;
- emblema;
- histórico.

## Eventos
Estados:
draft → review → published → registration/open → closed → completed/cancelled.

Campos:
- público;
- data/hora;
- local;
- capacidade;
- recursos;
- imagem;
- responsável;
- elegibilidade;
- aprovação.

## Notificações
First-party:
- ponto/estorno;
- quiz;
- missão;
- revisão;
- evento;
- recompensa;
- item;
- aviso institucional.

Sem marketing.
