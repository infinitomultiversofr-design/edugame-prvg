---
name: edugame-security
description: Revisa segurança, LGPD, RLS, auditoria, privacidade de menores e contratos de autorização do EduGame. Use antes de aprovar autenticação, dados sensíveis, relatórios, responsáveis, rankings, notificações, offline ou integrações externas.
---
# Segurança e privacidade

Leia `docs/02_ROLES_AND_PERMISSIONS.md`, `docs/12_SECURITY_PRIVACY_A11Y.md`, `docs/23_DATA_RETENTION_MATRIX_TEMPLATE.md` e `docs/pwa/04_AUTH_SECURITY_PRIVACY.md` quando houver PWA.

Regras inegociáveis:
- dados mínimos e por vínculo;
- comportamento/risco nunca em ranking público;
- responsável é somente leitura e apenas de estudante vinculado;
- auditoria para ação sensível;
- estorno em vez de apagar transação;
- sem anúncios, dinheiro real, loot boxes ou chat aberto entre menores;
- cache/offline nunca amplia autorização;
- logout/troca de conta limpa dados locais do usuário anterior.

Bloqueie merge se houver segredo em cliente, RLS ausente, endpoint privilegiado sem autorização server-side ou cache compartilhando dados entre usuários.
