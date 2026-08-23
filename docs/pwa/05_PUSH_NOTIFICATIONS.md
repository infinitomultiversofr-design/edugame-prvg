# PWA 05 — Web Push

## Escopo
Push é opcional e só entra após revisão de privacidade/consentimento e definição institucional de finalidade.

## Casos permitidos
- lembrete de atividade/evento;
- atualização de missão;
- conteúdo/revisão disponível;
- aviso operacional não sensível.

## Casos proibidos
- expor punição, ocorrência, risco ou nota na notificação;
- pressionar estudante com linguagem humilhante;
- marketing/anúncios;
- enviar dados de outro estudante/turma.

## Arquitetura
- VAPID public key pode ir ao cliente; private key somente servidor.
- subscription associada a usuário/dispositivo com timestamps e revogação.
- endpoint de subscribe/unsubscribe exige sessão válida.
- payload mínimo; detalhes são buscados após abrir o app e validar autorização.

## UX
Não pedir permissão na primeira tela. Pedir no contexto de valor claro e permitir recusa sem perda de funcionalidade essencial.

## Clique
`notificationclick` abre rota estável e neutra; autorização da rota ocorre depois. Não confiar em IDs do payload para autorização.

## Operação
Remover subscriptions 404/410, registrar taxa de entrega/erro sem armazenar conteúdo sensível e permitir opt-out por dispositivo.
