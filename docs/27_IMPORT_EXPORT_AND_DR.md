# 27 — Importação, Exportação e DR

## Importação
Pipeline:
upload → hash → parse → validate → preview → confirm → apply → report

Nunca aplicar planilha imediatamente após upload.

## Tipos
- estudantes;
- responsáveis;
- turmas;
- matrículas;
- quizzes históricos EduGame;
- transações legadas EduGame;
- notas acadêmicas apenas no domínio acadêmico.

## Relatório
Cada linha:
ok | warning | rejected
com motivo estável.

## Exportação
Jobs assíncronos:
- CSV/JSON;
- filtros;
- arquivo privado;
- URL temporária;
- audit log.

## Estorno
Operacional ≠ restore.

## DR
- backup banco;
- estratégia de objetos Storage separada;
- cópia em localização/conta independente quando política aprovada;
- inventário de buckets;
- criptografia;
- controle de acesso;
- restore drill documentado;
- postmortem de incidentes relevantes.
