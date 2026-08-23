# 04 — Design System Visual do EduGame

## Objetivo
Reproduzir a qualidade dos targets visuais sem transformar páginas em imagens clicáveis.

Toda interface deve ser HTML/CSS/SVG/Canvas real, com assets apenas onde necessário.

## DNA visual
“Sistema educacional sci-fi premium”: escuro, profundo, luminoso, amigável, legível e não militar.

## Paleta semântica
- Background principal: `#050817`
- Background alternativo: `#0D0D0D`
- Superfície: `#0C1230`
- Roxo principal: `#6E00FF`
- Roxo claro: `#A855F7`
- Ciano: `#00CFFF`
- Rosa/magenta: `#FF007A`
- Amarelo/dourado: `#FFD400`
- Sucesso: `#26E07F`
- Dica/atenção: `#FFAA33`
- Erro crítico: `#FF4D67`
- Texto: branco levemente azulado
- Texto secundário: cinza azulado

## Tipografia
- display: Space Grotesk ou equivalente livre;
- interface: Inter ou equivalente livre;
- números/placar: tabular nums.

## Geometria
- cantos grandes;
- borda fina com glow;
- superfícies translúcidas moderadas;
- recortes/HUD apenas decorativos;
- foco visível.

## Componentes canônicos
AppShell
TopBar
StudentBottomNav
AdultSidebar
NeonCard
GlassPanel
PrimaryButton
SecondaryButton
DangerButton
IconButton
Tabs
SegmentedControl
ProgressBar
XPBar
PointsBadge
LevelBadge
SubjectBadge
SkillBadge
StatusPill
AnswerOption
FeedbackPanel
HintPanel
PetBubble
VideoCard
GameCard
RankingRow
RewardCard
InventoryTile
AvatarStage
Dialog
Toast
Sheet
LoadingSkeleton
EmptyState
ErrorState
OfflineBanner

## Estados
Todo componente interativo:
default · hover · focus · pressed · selected · disabled · loading · error.

## Movimento
### Sucesso
borda verde/ciano, progressão, partículas pequenas, reação do Pet.

### Primeiro erro
âmbar, leve deslocamento, nunca “tela vermelha”.

### Erro final
explicação, transição para revisão.

### Navegação
transição curta, 180–320ms.

### Redução de movimento
`prefers-reduced-motion` remove partículas, parallax e movimentos não essenciais.

## WebGL
Permitido em:
- fundo do início;
- mapa/ilhas;
- Avatar Lab;
- palco do Pet;
- celebrações;
- ambientação da Arena.

Nunca bloquear:
- login;
- responder questão;
- ver histórico;
- professor lançar ponto;
- gestão acessar dado.

## Modos gráficos
### Low
sem shader, blur reduzido, partículas desligadas.

### Normal
transições e partículas leves.

### Immersive
WebGL, parallax, pós-processamento leve.

Escolha automática por capacidade + opção manual.

## Targets
Os arquivos em `reference-ui/` definem atmosfera e hierarquia.  
Não copiar erros de texto, números inconsistentes ou elementos decorativos sem função.
