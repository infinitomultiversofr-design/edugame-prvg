# 01 — Produto, Regras e Economia

## Proposta de valor
Transformar a rotina escolar em uma jornada visível de estudo, colaboração, organização e conquista, oferecendo feedback compreensível ao estudante e evidências acionáveis à escola.

## Três sistemas de progresso

### 1. Pontos individuais
Livro-razão oficial do estudante. Pode ter ganhos e deduções conforme regras da escola.

### 2. XP
Progressão positiva do perfil. Nunca diminui. Representa continuidade de aprendizagem e participação. Não substitui pontos oficiais.

### 3. Desbloqueios
Estado de inventário. Não é moeda. Itens podem ser liberados por ponto acumulado, nível, habilidade, missão, insígnia, evento ou regra administrativa.

Não criar gemas compráveis, dinheiro real ou saldo que incentive gasto.

## Três placares oficiais
- estudante;
- grupo;
- turma.

Cada transação tem exatamente um escopo.
O frontend nunca deve “converter” um tipo de pontuação em outro.

## Configuração histórica
Valores antigos do projeto são referência histórica e não devem ser codificados como regra fixa.
Exemplos:
- quiz já teve 8 questões × 2 pontos;
- Passe Livre já utilizou limiar de 16 pontos;
- turma já recebeu +1/-1 por limpeza e +1/-1 por organização.

Tudo deve ser parametrizável por escola, ano letivo, período e regra.

## Convivência
Deduções podem existir, mas:
- motivo detalhado é privado;
- ranking não exibe motivo;
- registro deve trazer orientação restaurativa quando aplicável;
- correção acontece por estorno;
- nenhum algoritmo decide punição automaticamente.

## Recompensas
Exemplos:
- Passe Livre;
- Sala Especial;
- sessão de cinema/pipoca;
- evento escolar;
- fundo/avatar/acessório;
- insígnia;
- experiência coletiva.

## Central de Recompensas
Visualmente pode lembrar uma loja de jogo, porém:
- nenhum item é comprado;
- nenhum ponto é consumido;
- mostrar “como desbloquear”, não “preço”;
- estado: bloqueado, elegível, desbloqueado, equipado.

## Ranking
Permitido:
- evolução positiva;
- turma/grupo;
- período definido;
- avatar/apelido moderado.

Proibido:
- motivo de dedução;
- ocorrência;
- risco;
- diagnóstico;
- deficiência;
- laudo;
- plano de ação;
- exposição de quem está “pior”.

A instituição pode ocultar ranking individual.
