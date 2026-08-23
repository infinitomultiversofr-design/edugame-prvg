---
name: edugame-arena
description: Implementa ou revisa Arcade e Arena multiplayer do EduGame, incluindo engines reutilizáveis, lobby, Realtime, reconexão, anti-cheat, quick-chat moderado e placar server-authoritative. Use em M6 ou M7.
---
# Arcade e Arena

Leia `docs/07_GAMES_ARENA_MULTIPLAYER.md` e contratos relacionados.

- Jogo oficial nunca confia em pontuação enviada pelo cliente.
- Realtime precisa de reconexão determinística e recuperação de estado.
- Quick-chat usa mensagens fechadas/moderadas; sem chat livre entre menores.
- Engines são reutilizáveis; conteúdo muda por pack, não por duplicação de código.
- M6 solo/assíncrono precede M7 multiplayer.
- Teste latência, duplicidade, refresh, reconexão, abandono e tentativa de adulterar payload.
