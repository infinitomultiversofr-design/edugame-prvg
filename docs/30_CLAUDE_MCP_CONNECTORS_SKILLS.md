# 30 — Claude, MCP, conectores e Skills

## Objetivo
Permitir que Claude Code trabalhe nesta pasta com contexto persistente, habilidades sob demanda e acesso controlado ao Supabase, sem embutir segredos no repositório.

## 1. Modos de uso
### Claude Code — recomendado para desenvolvimento
Abra um terminal na raiz `EduGame/` e execute `claude`. O agente lê `CLAUDE.md` e pode usar os Skills locais. O MCP do Supabase fica em `.mcp.json`.

### Claude Desktop / Claude.ai
Adicione o conector oficial Supabase na interface de Connectors e autorize a organização correta. Para alterações de código, abra a pasta como projeto/ambiente compatível ou use Claude Code.

## 2. Supabase MCP
Configuração padrão do pacote: **read-only + project-scoped**.

Variável local obrigatória:
```bash
export SUPABASE_PROJECT_REF="SEU_PROJECT_REF_DE_DEV"
```
No Windows PowerShell:
```powershell
$env:SUPABASE_PROJECT_REF="SEU_PROJECT_REF_DE_DEV"
```
Depois, no Claude Code:
```bash
claude
/mcp
```
Selecione `supabase` e autentique no navegador.

### Habilitar escrita
Somente para dev/staging e somente quando o ticket exigir migration/RPC/Edge Function. Copie temporariamente a configuração de `.mcp.write.example.json` para `.mcp.json`, revise o diff e mantenha aprovação manual das chamadas.

**Nunca** use o MCP de escrita em produção para desenvolvimento cotidiano.

## 3. Grupos de ferramentas habilitados
Padrão: `database,docs,debugging,development,functions`.

Não habilitamos `account` por padrão porque o projeto deve ficar restrito ao project ref. `branching` e `storage` são opcionais e só entram quando houver ticket explícito.

## 4. Agent Skills
Skills locais em `.claude/skills/`:
- `edugame-orchestrating`
- `edugame-supabase`
- `edugame-security`
- `edugame-pwa`
- `edugame-testing`
- `edugame-ui`
- `edugame-arena`

Cada Skill contém somente o fluxo principal e aponta para documentação canônica mais detalhada. Isso reduz contexto desnecessário.

### Skills oficiais do Supabase
Podem ser instalados localmente conforme a documentação oficial:
```bash
npx skills add supabase/agent-skills
```
Os Skills oficiais complementam os Skills EduGame; não substituem regras do projeto.

## 5. Conectores recomendados
- **Supabase** — obrigatório para inspeção/execução do banco no ambiente de desenvolvimento.
- **GitHub** — recomendado quando o repositório remoto estiver definido, para PRs/issues/revisão; não é requisito para ler a pasta local.
- **Google Drive** — opcional para consultar documentos institucionais; nunca usar Drive como banco operacional do app.
- **Canva/design tools** — opcionais para produção visual; referências finais aprovadas devem ser exportadas/versionadas no projeto.

## 6. Segredos
Não versionar: access tokens, PATs, `service_role`, VAPID private key, senhas, PINs ou `.env` real. Use `.env.example` apenas com nomes de variáveis e valores fictícios.

## 7. Política de autorização do agente
Leitura é ampla dentro do repositório; escrita exige contexto de ticket. Ações destrutivas, migrations, deploys e chamadas MCP de escrita devem continuar com aprovação humana.
