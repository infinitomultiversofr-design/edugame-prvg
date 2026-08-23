# 26 — API Error Contract

Formato lógico:
{
  "ok": false,
  "code": "QUIZ_CLOSED",
  "request_id": "...",
  "retryable": false
}

Não enviar stack trace ao client.

| Code | HTTP sugerido | Retry | Mensagem UI |
|---|---:|---:|---|
| AUTH_REQUIRED | 401 | não | Entre novamente para continuar. |
| FORBIDDEN_SCOPE | 403 | não | Você não tem acesso a esta área. Peça ajuda ao seu professor. |
| QUIZ_CLOSED | 409 | não | Este quiz não está disponível agora. |
| ATTEMPT_LIMIT | 409 | não | Você já usou as tentativas disponíveis para esta questão. |
| DUPLICATE_OPERATION | 409 | não | Esta ação já foi registrada. |
| NETWORK_UNAVAILABLE | client | sim | A conexão caiu. Vamos tentar novamente. |
| RATE_LIMITED | 429 | sim | Muitas tentativas em pouco tempo. Aguarde um momento. |
| INTERNAL_ERROR | 500 | talvez | Não conseguimos concluir agora. Tente novamente. |

Erros precisam ser anunciados por leitor de tela quando afetam a tarefa.
