# EduGame — START HERE

Este diretório é a **fonte canônica do projeto EduGame** para uso no Claude, ChatGPT Desktop, Codex ou outro agente de desenvolvimento.

## Estado atual

- **Blueprint v1.1:** APROVADO e congelado.
- **M0-A — Database Foundation:** código pronto, mas Gate ainda precisa ser executado em Supabase dev/staging.
- **M0 Final — Foundation completa:** ainda não aprovado; depende de M0-A + fundação da aplicação.
- **M1:** não iniciar antes do Gate M0 Final.

## O que já está especificado

O projeto completo está documentado do M0 ao M11, incluindo:

- jornada de aprendizagem;
- currículo/BNCC;
- quiz, feedback, revisão, vídeos e microquestões;
- três ledgers de pontuação;
- professor;
- família;
- gestão;
- Avatar Lab;
- 8 famílias anatômicas;
- catálogo de 200 animais;
- inventário e recompensas;
- Pet;
- missões;
- grupos;
- eventos;
- Arcade;
- Arena multiplayer;
- PWA/offline permitido;
- acessibilidade;
- performance;
- multi-escola;
- segurança, RLS, auditoria e Disaster Recovery;
- referências visuais do Quiz, Arena, Avatar e Pet.

## Ordem obrigatória de leitura

1. `AGENTS.md`
2. `EDUGAME_CODEX_MASTER_SPEC.md`
3. `CODEX_HANDOFF.md`
4. `PROJECT_CONTEXT.md`
5. `ROADMAP_M0_M11.md`
6. `GATE_M0A_DATABASE.md`
7. `GATE_M0_FINAL.md`
8. `docs/`
9. `reference-ui/`

## Fonte da verdade

Se houver conflito:

1. segurança/privacidade;
2. `EDUGAME_CODEX_MASTER_SPEC.md`;
3. `AGENTS.md`;
4. documentos canônicos em `docs/`;
5. Gates atuais;
6. migrations/testes versionados;
7. referências visuais;
8. conversas antigas.

A conversa que originou o projeto é **histórico**, não configuração executável.

## Regra principal

> Não construir o EduGame inteiro de uma vez. Trabalhar um recorte vertical por vez e só avançar após o Gate do marco.

## Próxima ação

A primeira ação de engenharia é validar o **Gate M0-A — Database Foundation** em um Supabase isolado.

Depois:
- completar a fundação da aplicação;
- aprovar o Gate M0 Final;
- iniciar M1, o Vertical Slice do João.

Leia `PROMPTS/01_PRIMEIRA_MENSAGEM_AGENT.md` para iniciar uma nova sessão no Claude ou ChatGPT Desktop.


## Claude + MCP
Para Claude Code, leia também `CLAUDE.md`, `docs/30_CLAUDE_MCP_CONNECTORS_SKILLS.md` e `docs/31_CLAUDE_EXECUTION_PLAYBOOK.md`.
O Supabase MCP padrão está em `.mcp.json` em modo read-only e exige `SUPABASE_PROJECT_REF` de dev/staging.
A documentação PWA completa começa em `docs/pwa/00_PWA_MASTER_SPEC.md`.
