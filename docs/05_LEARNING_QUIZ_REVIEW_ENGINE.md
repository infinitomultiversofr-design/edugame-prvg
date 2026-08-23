# 05 — Motor de Aprendizagem, Quiz, Revisão e Vídeo

## Modelo pedagógico
Responder → feedback → nova tentativa → resolução → revisão → recurso → microverificação → recuperação.

## Currículo
Todo conteúdo pode se vincular a:
- escola;
- ano letivo;
- ano/série;
- componente curricular;
- trimestre/período;
- habilidade BNCC;
- descritor local/SAEB quando aplicável;
- nível cognitivo/Bloom;
- dificuldade.

Os documentos curriculares fornecidos pela escola são fonte de importação e curadoria. Codex não deve inventar currículo em migrations.

## Questão
Campos mínimos:
- enunciado;
- tipo;
- quatro alternativas para múltipla escolha;
- gabarito em tabela protegida;
- feedback por alternativa;
- dica;
- resolução;
- imagem opcional;
- áudio opcional;
- vídeo/recurso associado;
- habilidade;
- dificuldade;
- status de moderação.

## Política padrão de tentativas
Configurável. Padrão inicial:
- 2 tentativas;
- acerto na primeira: pontuação integral;
- erro na primeira: mostrar dica sem revelar resposta;
- acerto na segunda: pontuação reduzida;
- erro na segunda: resolução completa e `needs_review`.

O valor exato de pontos vem de política versionada, nunca do componente.

## Feedback de acerto
Não mostrar apenas “correto”.
Exibir:
- o que o estudante percebeu;
- trecho/equação/conceito visualmente marcado;
- explicação curta;
- habilidade relacionada;
- pontos/XP concedidos pelo servidor.

Exemplo de Português:
tese destacada em roxo, argumentos em ciano.

## Feedback de erro
### Erro 1
- linguagem acolhedora;
- dica;
- manter pelo menos duas opções plausíveis;
- botão “tentar novamente”.

### Erro 2
- resposta e resolução;
- zero ou regra definida;
- adicionar habilidade à revisão;
- recurso recomendado.

## Estados de aprendizagem
- `not_started`
- `in_progress`
- `mastered_direct`
- `mastered_with_support`
- `needs_review`
- `recovered_after_review`

Estes estados descrevem a experiência imediata. Um perfil longitudinal de habilidade deve usar múltiplas evidências e não declarar “domínio permanente” por uma única questão.

## Quiz semanal
Formato-base histórico:
1 questão por componente:
- Língua Portuguesa
- Matemática
- Ciências
- Geografia
- Língua Inglesa
- História
- Educação Física
- Arte

O sistema suporta outros formatos.

## Checkpoint
Após parte do quiz, pode haver pausa visual:
- concluídas;
- diretas;
- com dica;
- em revisão;
- próxima matéria.

## Resultado
Não limitar a “7/8”.
Mostrar:
### Já demonstra
acertos diretos.

### Conseguiu com apoio
acertos após dica.

### Vamos fortalecer
habilidades que terminaram em erro.

## Revisão inteligente
Ordenação:
1. prioritário: `needs_review`;
2. recomendado: `mastered_with_support`;
3. opcional: `mastered_direct`.

## Recurso em vídeo
Pode ser:
- YouTube curado;
- vídeo próprio;
- outro provedor autorizado.

Guardar:
- título;
- URL/provider;
- duração;
- thumbnail;
- resumo;
- transcrição/legenda quando disponível;
- habilidade;
- curador;
- status de aprovação.

Assistir não gera ponto automaticamente.

## Player
- progresso;
- legenda;
- transcrição;
- resumo;
- recomendação do Pet;
- botão microquestão;
- retomada do ponto do vídeo.

## Microquestão
Objetivo: verificar se o reforço produziu compreensão.
- simples;
- vinculada à habilidade;
- sem copiar necessariamente a questão original;
- resultado registra `recovered_after_review` quando critérios forem atendidos.

## Métricas de comportamento de aprendizagem
Privadas para análise pedagógica:
- latência até iniciar;
- persistência após primeiro erro;
- conclusão de revisão;
- recuperação após conteúdo;
- autonomia (início sem lembrete, quando possível medir).

Nunca usar essas métricas isoladamente para punição ou rótulo.
