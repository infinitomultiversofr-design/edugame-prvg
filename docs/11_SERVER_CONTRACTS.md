# 11 — Contratos Server-Side / RPC

Os nomes abaixo são contratos conceituais. Implementação pode usar RPC PostgreSQL, Route Handler ou Edge Function, mas ações sensíveis nunca ficam somente no cliente.

## Estudante

### `get_my_dashboard()`
Deriva estudante via auth.uid().
Retorna apenas dados autorizados.

### `start_my_quiz(p_quiz_id)`
Valida:
- estudante;
- matrícula;
- público;
- janela;
- sessão existente.
Retorna session id e primeira questão sanitizada.

### `get_my_quiz_question(p_session_id, p_sequence)`
Sem gabarito.
Retorna alternativas sem `is_correct`.

### `submit_my_answer(p_session_id, p_question_id, p_option_key, p_idempotency_key)`
Servidor:
- deriva aluno;
- lock por sessão/questão;
- valida alternativa;
- calcula attempt_no;
- verifica gabarito;
- aplica política;
- grava tentativa;
- lança ponto se houver;
- grava skill event;
- retorna estado pedagógico autorizado.

Nunca recebe `is_correct`, `points` ou `student_id`.

### `complete_my_quiz(p_session_id)`
Finaliza uma vez.
Retorna resumo por habilidade.

### `get_my_review_queue()`
Prioridade sem expor dados de terceiros.

### `record_my_resource_progress(...)`
Somente progresso.
Não concede ponto automático.

### `submit_my_micro_check(...)`
Valida gabarito no servidor e registra recuperação.

### `save_my_avatar(...)`
Valida:
- espécie disponível;
- itens possuídos;
- compatibilidade/adaptação;
- conteúdo moderado.

### `set_my_pet(...)`
Valida posse e nome moderado.

## Pontuação professor

### `post_score_transaction(...)`
Parâmetros:
- ledger_type;
- target ids;
- rule_id;
- reason;
- subject_id opcional;
- idempotency_key.

Servidor deriva ator e valida atribuição.

### `post_score_batch(...)`
Mostra preview antes e grava atomicamente quando possível.

### `reverse_score_transaction(p_transaction_id, p_reason)`
Cria transação inversa vinculada.

## Quiz professor
`create_quiz_draft`
`add_question_to_quiz`
`publish_quiz`
`close_quiz`
`start_live_quiz`

Publicação valida:
- questões aprovadas;
- habilidade;
- público;
- regra;
- janela.

## Arena
`create_game_room`
`join_game_room`
`set_player_ready`
`start_game_room`
`submit_game_action`
`finish_game_room`

Placar final é gerado no servidor.

## Desbloqueio
`claim_unlock(p_unlockable_type,p_id)`
Servidor avalia regra atual.
O cliente nunca insere inventário diretamente.

## Admin
Provisionamento de estudante deve ocorrer por ambiente administrativo seguro/Edge Function:
- cria Auth;
- vincula student.user_id;
- gera/rotaciona PIN;
- nunca devolve service role ao navegador.

## Erros
Usar códigos estáveis:
AUTH_REQUIRED
FORBIDDEN_SCOPE
QUIZ_CLOSED
QUIZ_NOT_ASSIGNED
QUESTION_NOT_IN_QUIZ
ATTEMPT_LIMIT
INVALID_OPTION
DUPLICATE_OPERATION
ITEM_NOT_OWNED
ITEM_INCOMPATIBLE
ROOM_FULL
ROOM_CLOSED
RATE_LIMITED

UI traduz códigos; não depende de parsing de mensagem livre.
