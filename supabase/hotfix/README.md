# Hotfix — `/quiz` público no app EduGame PRVG

Achado em 2026-08-23 durante a revisão da fundação M0, ao ler o código do
projeto Lovable `edugameprvg` (`259c2325`), que aponta para o Supabase
`amvfodigcecsbvlmobrx` e está publicado em `edugameprvg.lovable.app`.

Não foi verificado no banco: o MCP do Supabase não estava autorizado nesta
sessão. Tudo abaixo vem de `supabase/sql/00_quiz_legacy.sql` e
`src/pages/Quiz.tsx` do projeto Lovable. **Confirme no banco antes de agir.**

---

## O problema

`00_quiz_legacy.sql` dá ao papel `anon` — cujo token está no bundle publicado,
por design público — acesso direto às tabelas do quiz:

```sql
GRANT SELECT ON public.students TO anon;
CREATE POLICY "quiz_public_read_students" ON public.students
  FOR SELECT TO anon USING (active = true);

GRANT INSERT ON public.transactions TO anon;
CREATE POLICY "quiz_public_insert_tx" ON public.transactions
  FOR INSERT TO anon
  WITH CHECK (points = 1 AND created_by = 'Quiz Online' AND rule_id IN (...));
```

Quatro consequências, independentes entre si:

**1. O gabarito vai para o navegador.** `Quiz.tsx` seleciona
`correct_answer, correct_answer_normalized` e corrige em JS:

```js
isCorrect = normalizeAnswer(given) === normalizeAnswer(q.correct_answer);
```

Basta abrir o DevTools na aba Network para ler as respostas antes de responder.

**2. O cliente escreve o ledger de pontos.** O `transactionsPayload` é montado
no navegador e inserido direto em `transactions`. A policy não checa
`student_id`, não exige que exista resposta correspondente e não limita
volume. Com a chave anon e um `curl`, dá para injetar `+1` ilimitado para
qualquer aluno, sem login.

**3. Dados de menores expostos.** `GRANT SELECT ON public.students TO anon` é
em todas as colunas, para todos os alunos ativos de todas as turmas.
`quiz_responses` tem `USING (true)` — qualquer um lê as respostas de qualquer
aluno.

**4. O bloqueio semanal não bloqueia.** `step = "blocked"` é decisão do
JavaScript, e a inserção de pontos não depende dela.

Isso contraria diretamente a regra inegociável do `CLAUDE.md`: *"nunca confiar
no cliente para acerto, pontuação, desbloqueio, autorização ou identidade de
terceiros"*.

---

## Ordem de aplicação

| # | Arquivo | O que faz |
|---|---|---|
| 1 | `2026-08-23_01_contencao_quiz_anon.sql` | Remove todo acesso de `anon` às tabelas. **Quebra o `/quiz`.** |
| 2 | `2026-08-23_02_quiz_server_authoritative.sql` | Cria as três RPCs que devolvem o quiz funcionando, agora com correção no servidor. |
| 3 | `quiz-data-client.ts` | Vai para `src/lib/quizData.ts` no projeto Lovable. |
| 4 | Editar `src/pages/Quiz.tsx` | Trocar os 6 acessos diretos por `lookupClass` / `startQuiz` / `submitQuiz`. |

Se precisar parar a exposição **agora** e só depois cuidar do resto, rode o
arquivo 1 sozinho. O quiz fica fora do ar, o resto do app (que usa
`authenticated`) continua funcionando.

Antes do arquivo 2, confira os nomes de coluna — o cabeçalho dele traz a query
de verificação e a lista de suposições que fiz a partir do código.

---

## Depois de aplicar

O arquivo 1 traz, comentadas no fim, duas consultas de conferência (nenhuma
policy nem grant sobrando para `anon`) e duas de avaliação de dano — quantos
lançamentos `'Quiz Online'` existem por aluno/semana acima do máximo legítimo,
e quais não têm acerto registrado correspondente. Transação sem acerto é o
indício mais direto de injeção.

Vale rodar os advisors do Supabase depois (`get_advisors`, security +
performance).

---

## O que este hotfix não resolve

O `/quiz` não tem login: o aluno escolhe o próprio nome numa lista. Quem
souber o código da turma continua podendo responder no lugar de um colega.
Não há correção possível no banco para isso — as saídas são código de acesso
por aluno ou autenticação de verdade.

É exatamente o que a fundação M0 deste repositório entrega: `school_memberships`
com papel e status, RLS por vínculo ativo, e escrita de pontuação apenas
server-side. Trate este hotfix como contenção com o quiz funcionando, não como
desenho final — a migração do app para o M0 continua sendo o caminho.
