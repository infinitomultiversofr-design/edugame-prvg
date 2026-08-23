# Cache versioning policy

Caches usam versão de build/conteúdo. Alteração incompatível de shell incrementa build. Alteração de conteúdo baixável incrementa content version.

Ativação remove caches obsoletos após garantir que nenhum item pendente depende deles. Nunca usar cache sem prefixo/versionamento.
