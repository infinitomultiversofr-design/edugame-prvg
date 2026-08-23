# EduGame — Status do Baseline

## Baseline montado

O repositório reúne o Blueprint v1.1, os documentos canônicos, os dados iniciais, as referências visuais, o handoff, a fundação M0 e o checklist do Gate M0.

A fonte canônica está organizada conforme o `CODEX_HANDOFF.md`: `AGENTS.md`, especificação mestre, `docs/`, changelog, checklist, migrations/testes versionados e `reference-ui/`.

## Validações realizadas

- O arquivo `scripts/m0-gate.mjs` passou na verificação sintática do Node.js.
- As sete migrations `0001`–`0007` existem e não estão vazias.
- `supabase/seed.sql` existe e não está vazio.
- Os seis testes SQL do M0 estão presentes.
- O repositório Git foi inicializado com o commit `docs: freeze EduGame blueprint v1.1 and M0 foundation`.
- O working tree está limpo.

## Gate M0 ainda não aprovado

A aprovação permanece pendente porque o checklist exige aplicar as migrations, executar o seed apenas em ambiente de desenvolvimento/teste e rodar os testes RLS com Auth real em um Supabase isolado. Essas evidências não foram produzidas neste ambiente local.

## Pendência de pacote

`EduGame_Codex_Handoff.zip` foi recebido, mas está truncado/inválido como arquivo ZIP. O `CODEX_HANDOFF.md` separado foi incorporado e é suficiente para manter as instruções do handoff; o ZIP inválido não foi usado como fonte.

## Próximo recorte

Depois de configurar um projeto Supabase dev/staging e aprovar o Gate M0, executar somente `S1-01 — Repository Foundation`. Não iniciar Quiz, Avatar, Pet, Arena, Professor ou Gestão antes desse gate.
