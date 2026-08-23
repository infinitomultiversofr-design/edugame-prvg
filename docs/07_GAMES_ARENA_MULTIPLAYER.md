# 07 — Jogos, Arcade e Arena Multiplayer

## Princípio
O catálogo deve ter sensação de portais de jogos múltiplos, mas todos os jogos do núcleo EduGame são:
- curados;
- não violentos;
- pedagogicamente vinculáveis;
- sem anúncios;
- sem compra;
- sem contato com desconhecidos;
- com sessão validada.

## Dois modos

### Arcade
individual ou assíncrono.

### Arena
competição online entre estudantes autorizados da mesma escola/rede conforme política.

## Motores reutilizáveis
Não criar 100 códigos independentes. Criar engines que recebem content packs.

### E01 Rapid Choice
Escolha rápida.

### E02 Word Assembly
Sílabas/palavras/frases.

### E03 Memory Match
Pares.

### E04 Pattern Puzzle
Sequências e lógica.

### E05 Sort & Classify
Classificação.

### E06 Timeline
Ordenação cronológica.

### E07 Map Challenge
Localização/Geografia.

### E08 Sentence Builder
Línguas.

### E09 Process Sequencer
Ciências/processos.

### E10 Data Detective
Gráficos/tabelas.

### E11 Listening Sprint
Áudio e língua.

### E12 Collaborative Puzzle
Equipe resolve problema em partes.

## Catálogo inicial de jogos

1. Duelo de Cálculo
2. Corrida das Palavras
3. Memória Científica
4. Padrões & Lógica
5. Quiz Relâmpago
6. Descubra a Palavra
7. Código Secreto
8. Linha do Tempo
9. Mapa Misterioso
10. Classifica!
11. Construtor de Frases
12. Laboratório em Ordem
13. Detetive de Dados
14. Missão Biomas
15. Vocabulário Turbo
16. Conexões
17. Sequência Rápida
18. Caça-Conceitos
19. Rota da História
20. Desafio de Estimativa
21. Equação Express
22. Inglês em Movimento
23. EcoMapa
24. Desafio Cooperativo

Nenhum jogo “Forca”.
Nenhum jogo com tiro, tanque, arma, combate ou eliminação física.

## Arena — criação de sala
Tipos:
- partida rápida por turma;
- código de sala;
- professor inicia;
- convite entre colegas autorizados;
- torneio escolar.

## Estado da sala
lobby → ready → countdown → active → results → closed.

## Servidor autoritativo
Cliente envia ação bruta.
Servidor:
- valida jogador;
- valida rodada;
- valida tempo;
- valida resposta;
- calcula placar;
- publica estado.

## Quick-chat
Estudantes:
- emojis;
- frases pré-moderadas: “Boa!”, “Vamos!”, “Quase!”, “Parabéns!”, “Pronto?”.
Sem texto livre no multiplayer base.

Professor pode moderar/encerrar sala.

## Pontuação de jogo
Separar:
- score da partida;
- XP;
- pontos oficiais.

Ponto oficial só é concedido por regra explícita e com limite.

## Fairness
- perguntas equivalentes em dificuldade;
- latência não deve determinar tudo;
- modos podem pontuar precisão + raciocínio;
- acessibilidade de tempo;
- opção sem cronômetro para necessidade pedagógica;
- nenhum ranking público de erro.

## Reconexão
Jogador desconectado tem janela configurável para voltar.
Estado da partida fica no servidor.

## Espectador
Professor pode acompanhar.
Estudante não vê painel de dados privados.

## Anti-cheat
- sem gabarito no cliente;
- nonce/round id;
- timestamps server-side;
- idempotência;
- rate limiting;
- detecção de replay;
- resultado final gerado no servidor.
