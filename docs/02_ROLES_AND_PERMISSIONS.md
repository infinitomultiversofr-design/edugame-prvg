# 02 — Perfis, Escopos e Permissões

## Regra geral
Autorização = papel + vínculo + escola + ano letivo.

Possuir papel “professor” não libera todas as turmas.
Possuir papel “responsável” não libera todos os estudantes.

## Estudante
Pode:
- ver apenas a própria trajetória;
- responder atividades próprias;
- participar de salas escolares autorizadas;
- editar preferências e identidade visual permitidas;
- ver progresso da própria turma/grupo conforme política.

Não pode:
- editar pontos;
- conceder recompensa;
- consultar dados privados de colegas;
- responder como outro estudante;
- ler gabarito antes do momento autorizado.

## Professor
Escopo: atribuições de turma/componente.
Pode:
- pontos;
- quizzes;
- grupos;
- missões;
- conteúdo;
- ocorrências;
- relatórios;
- sessão ao vivo.

Ações sensíveis exigem confirmação e auditoria.

## Pedagogia/Coordenação
Escopo: escola/turmas autorizadas.
Pode:
- intervenções;
- aprovação de conteúdo;
- análise de aprendizagem;
- análise de convivência;
- planos de ação;
- acompanhamento de ocorrências.

## Direção
Escopo: escola.
Pode:
- regras;
- recompensas;
- eventos;
- indicadores;
- relatórios institucionais;
- configurações aprovadas.

## Administração escolar
Pode:
- usuários;
- matrículas;
- turmas;
- ano letivo;
- importações;
- marca;
- permissões locais.

## Responsável
Somente leitura.
Pode:
- selecionar estudante vinculado;
- resumo;
- histórico;
- aprendizagem;
- recompensas;
- pergunta da semana;
- eventos;
- avisos.

Não pode:
- enviar resposta pelo estudante;
- alterar cadastro escolar;
- lançar ponto;
- abrir conversa privada com aluno/professor pelo produto base.

## Administração de rede
Futuro.
Gerencia múltiplas escolas e padrões comuns sem quebrar isolamento local.

## Matriz resumida
| Domínio | Estudante | Professor | Coordenação | Direção | Responsável | Admin |
|---|---|---|---|---|---|---|
| Próprio perfil | RW limitado | R | R | R | R vinculado | RW |
| Pontos | R próprio | W escopo | R/W autorizado | R/W regra | R vinculado | administração |
| Quiz | responder | criar/publicar | aprovar/acompanhar | indicadores | R resultado | configuração |
| Ocorrência | R própria filtrada | W escopo | RW | R | somente quando autorizado | configuração |
| Avatar | RW próprio | - | moderação | conteúdo | R | catálogo |
| Gestão | - | turma | escola | escola | - | escola/rede |
