# 22 — Lifecycle e Versionamento de Conteúdo

## Estados
draft
pedagogical_review
rejected
approved
published
archived

`approved` e `published` podem ser combinados na implementação se a política não exigir agendamento,
mas manter conceitos distintos no domínio.

## Regras
- apenas draft é livremente editável;
- enviar para review cria snapshot imutável da versão;
- reviewer não deve ser o próprio autor quando a política exigir dupla checagem;
- rejected exige nota;
- edição de published cria nova versão;
- publicação nova troca ponteiro ativo atomicamente;
- histórico não é apagado.

## IA
Toda saída de IA:
- `generated_by_ai = true`;
- modelo/proveniência quando aplicável;
- entra em draft;
- precisa revisão humana antes de publicação.
