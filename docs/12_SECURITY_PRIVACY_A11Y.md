# 12 — Segurança, LGPD, Privacidade e Acessibilidade

## Autenticação

### Estudante
Tela pede:
- ID EduGame;
- PIN.

Implementação usa Supabase Auth com credencial técnica não exibida.
Cadastro público desligado.
PIN:
- gerado administrativamente;
- aleatório;
- rotacionável;
- rate limiting;
- nunca logado em texto.

### Adultos
Preferir e-mail institucional/autorizado com método forte disponível.

## Autorização
RBAC + vínculo.
RLS é obrigatória em todas as tabelas acessíveis via API.

## Dados de menores
- minimização;
- finalidade clara;
- sem publicidade;
- sem venda;
- sem tracking publicitário;
- retenção definida;
- exportação controlada;
- acesso sensível auditado.

A base legal/consentimentos deve ser validada institucionalmente antes de portal familiar em produção.

## Dados de convivência
Separação lógica e política.
Narrativa privada nunca entra em:
- ranking;
- notificação pública;
- chat;
- exportação comum;
- dashboard estudantil de terceiros.

## Logs
Nunca registrar:
- PIN;
- service role;
- tokens;
- conteúdo sensível desnecessário;
- gabarito em analytics client-side.

## Moderação
Moderável:
- apelido;
- nome do Pet;
- nome/lema de grupo;
- uploads;
- imagens;
- questões;
- vídeos;
- jogos;
- eventos.

## Conteúdo externo
Links e vídeos passam por curadoria.
Nada de embed publicitário quando houver alternativa viável; usar privacy-enhanced mode/provider configuration quando aplicável.

## Acessibilidade
Referência WCAG 2.2 AA.

Obrigatório:
- navegação por teclado;
- focus visible;
- labels;
- contraste;
- não depender de cor;
- texto escalável;
- `aria-live` para feedback;
- alt text;
- legendas/transcrição de vídeo;
- controles de áudio;
- redução de movimento;
- tempo ajustável em atividades quando necessário;
- área de toque adequada;
- idioma pt-BR;
- leitura de números e fórmulas compreensível.

## Segurança de multiplayer
- somente ambiente escolar autorizado;
- código de sala expira;
- quick-chat moderado;
- report/encerrar;
- teacher moderation;
- sem descoberta pública global de crianças;
- apelido/animal no placar, ID real só no backend.

## Threat model mínimo
Testar:
- IDOR;
- privilege escalation;
- RLS bypass;
- duplicate rewards;
- replay de resposta;
- leitura de gabarito;
- brute force PIN;
- XSS em nomes;
- upload malicioso;
- exposição de signed URL;
- CSRF quando aplicável;
- sessão em dispositivo compartilhado.
