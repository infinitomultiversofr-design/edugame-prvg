# PWA 10 — Testes de aceitação

## Instalação
- [ ] manifest válido, ícones 192/512 e display standalone.
- [ ] app continua utilizável sem instalar.
- [ ] instalação funciona em HTTPS suportado.

## Primeiro carregamento e offline
- [ ] após visita online concluída, abrir shell offline.
- [ ] primeira visita totalmente offline mostra estado correto, não tela quebrada.
- [ ] navegação offline não revela dados de outro usuário.

## Conta compartilhada
- [ ] login A → baixar snapshot → logout → login B: nenhum dado de A aparece.
- [ ] trocar organização não reutiliza snapshot anterior.

## Quiz/pontuação
- [ ] ficar offline antes de enviar: UI não declara acerto nem ponto.
- [ ] reconectar e enviar duas vezes com mesma idempotency key: uma única operação no servidor.
- [ ] editar payload local para incluir pontos/is_correct: servidor ignora/rejeita.

## Avatar/Pet
- [ ] preview offline funciona.
- [ ] item não possuído adulterado localmente é rejeitado pelo servidor.
- [ ] rejeição restaura estado confirmado com mensagem acessível.

## Vídeo/leitura
- [ ] progresso offline persiste.
- [ ] reconciliação não reduz progresso confirmado sem regra explícita.

## Cache
- [ ] SW novo remove cache obsoleto sem apagar fila pendente.
- [ ] API privada não aparece em Cache Storage genérico.
- [ ] logout purga material privado.

## Update
- [ ] update disponível durante atividade não recarrega à força.
- [ ] aplicar update em ponto seguro mantém sessão/estado compatível.
- [ ] migração IndexedDB falha de modo recuperável.

## Push
- [ ] permissão só é solicitada após ação/contexto do usuário.
- [ ] notificação não mostra dado sensível em lock screen.
- [ ] unsubscribe por dispositivo funciona.

## Performance/a11y
- [ ] budgets passam no aparelho-alvo.
- [ ] modo Low remove recursos pesados.
- [ ] teclado/foco/screen reader nos fluxos críticos.
- [ ] prefers-reduced-motion respeitado.

## Rede degradada
- [ ] 3G/alta latência não dispara duplicatas.
- [ ] backend 500 gera retry controlado, não loop.
- [ ] 401/403 pausa sync e exige reautenticação, não retry infinito.
