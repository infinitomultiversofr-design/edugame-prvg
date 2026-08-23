# 17 — Protocolo de Execução para Codex

## O Codex deve trabalhar em tickets verticais

Formato de ticket:

### Contexto
Qual fluxo e qual usuário.

### Resultado
O que deve funcionar do ponto A ao ponto B.

### Dados
Entidades e contratos envolvidos.

### UI target
Qual arquivo de `reference-ui`.

### Segurança
Ameaças específicas.

### Critérios
Given/When/Then.

### Testes
Lista obrigatória.

## Primeiro ticket recomendado

### M0.1 — Foundation Repository
Criar/normalizar:
- Next;
- TS strict;
- Tailwind;
- aliases;
- lint;
- test;
- Playwright;
- env validation;
- Supabase client server/browser separados;
- shell;
- design tokens;
- feature flags;
- CI.

Não implementar quiz ainda.

## Segundo
M0.2 Auth real.

## Terceiro
M1.1 Quiz session read-only.

## Quarto
M1.2 submit_answer seguro.

## Quinto
M1.3 telas de feedback.

## Sexto
M1.4 review + video + microcheck.

## Prompt padrão para cada execução

“Leia AGENTS.md e os documentos do módulo. Inspecione a base atual. Implemente somente [TICKET]. Preserve o Design System e as regras server-authoritative. Não altere módulos fora do escopo sem bloquear o ticket. Adicione testes. Ao final, liste mudanças, migrations, comandos executados, evidências e pendências.”

## Commit discipline
Commits pequenos:
- feat(auth):
- feat(quiz):
- fix(rls):
- test(quiz):
- docs(adr):
- refactor(ui):

## ADR
Criar ADR quando mudar:
- stack;
- schema central;
- auth;
- ledger;
- realtime;
- storage;
- offline;
- design system;
- política de segurança.

## Definition of Review
PR precisa permitir que outra pessoa:
- entenda;
- rode;
- teste;
- reverta;
- audite.
