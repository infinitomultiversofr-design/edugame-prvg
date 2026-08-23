# 03 — Catálogo de Telas e Rotas

## Público
- `/login`
- `/help`
- `/privacy`
- `/accessibility`

## Estudante

### S01 Entrada / onboarding — `/student/onboarding`
ID EduGame + PIN, tutorial, tema, acessibilidade e primeira escolha visual.

### S02 Início — `/student`
Resumo da semana, pontos, XP, missão, quiz, evento, progresso da turma/grupo, atalhos.

### S03 Meu progresso — `/student/progress`
Componentes, habilidades, participação, retomadas, sequência e metas pessoais.

### S04 Histórico — `/student/history`
Transações próprias, data, regra, origem, motivo permitido e estornos.

### S05 Aprender — `/student/learn`
Trilhas, disciplinas, habilidades, pendências e revisões.

### S06 Quiz — `/student/quiz/[quizId]`
Fluxo completo pedagógico.

### S07 Pergunta da semana — `/student/family-prompt`
Roteiro de conversa familiar, sem pontuação da família.

### S08 Missões — `/student/missions`
Individuais, grupo e turma.

### S09 Jogos — `/student/games`
Catálogo em grade tipo portal de jogos, porém curado e educacional.

### S10 Vídeos — `/student/videos`
Conteúdo por habilidade, progresso e recomendações.

### S11 Offline — `/student/offline`
Conteúdo baixado, apenas práticas permitidas.

### S12 Sala e grupo — `/student/community`
Metas, papéis, progresso e colaboração.

### S13 Ranking — `/student/rankings`
Escopos positivos e configuráveis.

### S14 Recompensas — `/student/rewards`
Passe Livre, Sala Especial, eventos e desbloqueios.

### S15 Calendário — `/student/calendar`
Eventos, quiz, missão e períodos.

### S16 Insígnias/Coleção — `/student/collection`
Animais, itens, conquistas e inventário.

### S17 Perfil — `/student/profile`
Dados de exibição, estatísticas e privacidade.

### S18 Avatar Lab — `/student/avatar`
Editor de animal, corpo, cor, roupa, acessórios, item especial, Pet, fundo e efeito.

### S19 Pet — `/student/pet`
Pet equipado, nome, nível, expressões, histórico de evolução.

### S20 Arena — `/student/arena`
Jogos competitivos online escolares.

### S21 Sala Arena — `/student/arena/room/[roomId]`
Lobby, jogadores, rodadas, placar e quick-chat.

### S22 Revisão inteligente — `/student/review`
Prioritário, recomendado e opcional.

### S23 Player de reforço — `/student/review/resource/[id]`
Vídeo, resumo, transcrição, progresso e microquestão.

### S24 Notificações — `/student/notifications`
Eventos first-party relevantes.

### S25 Configurações — `/student/settings`
Acessibilidade, gráficos, som, notificações e sessão.

## Professor

T01 `/teacher`
T02 `/teacher/classes`
T03 `/teacher/students/[id]`
T04 `/teacher/groups`
T05 `/teacher/points`
T06 `/teacher/transactions`
T07 `/teacher/questions`
T08 `/teacher/quizzes`
T09 `/teacher/live`
T10 `/teacher/missions`
T11 `/teacher/incidents`
T12 `/teacher/content`
T13 `/teacher/events`
T14 `/teacher/reports`
T15 `/teacher/settings`

## Responsável

R01 `/family`
R02 `/family/student/[id]`
R03 `/family/student/[id]/history`
R04 `/family/student/[id]/learning`
R05 `/family/student/[id]/rewards`
R06 `/family/student/[id]/weekly`
R07 `/family/events`
R08 `/family/settings`

## Gestão/Admin

G01 `/manage`
G02 `/manage/classes/[id]`
G03 `/manage/learning`
G04 `/manage/attention`
G05 `/manage/behavior`
G06 `/manage/action-plans`
G07 `/manage/rules`
G08 `/manage/rewards`
G09 `/manage/events`
G10 `/manage/content`
G11 `/manage/people`
G12 `/manage/academic-year`
G13 `/manage/audit`
G14 `/manage/reports`
G15 `/manage/branding`

## Rede futura
`/network/*`

## Responsividade
- desktop: sidebar + grid;
- tablet: rail ou top nav;
- mobile: bottom navigation para estudante; menu compacto para adulto;
- nenhuma função pode existir somente em desktop.
