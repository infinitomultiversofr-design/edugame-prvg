# CLAUDE.md — EduGame PRVG

## Visão Geral

Plataforma de gamificação escolar brasileira. **Arquivo único**: `index.html` (HTML + CSS + JS inline). Sem build, sem dependências, sem package manager.

- Idioma: **pt-BR** — todo texto de UI, variáveis e dados em português
- Stack: Vanilla HTML5 / CSS3 / JS (ES6+)
- Persistência: `window.storage.get/set('eg-v4')`
- Deploy: qualquer host estático, funciona via `file://`

## Estrutura

```
edugame-prvg/
├── index.html    # App completo
├── landing.html  # Landing page marketing
└── CLAUDE.md
```

## Boot Flow

```
window.load → boot() → loadDB() → renderWelcome() → [login] → showDash()
```

`loadDB()` lê do storage; se vazio, `seed()` gera dados de teste.

## Roles e Seções DOM

| Role | Tipo (`CU.type`) | Seção DOM |
|------|-----------------|-----------|
| Estudante | `student` | `#stuDash` |
| Professor | `professor` | `#profDash` |
| Coordenador | `coordinator` | `#coDash` |
| Diretor | `director` | `#dirDash` |

`CU` = Current User (global). `DB` = Database (global).

## Modelo de Dados

```javascript
DB = {
  turmas: [],      // {id, name, shift, rp, grade, pipocaUsed}
  students: [],    // {id, name, user, pass, avatar, tid, pts, wp, lost, wq, hadPass, pltw, prtw}
  coordinators:[], // {id, name, user, pass, avatar}
  professors:[],   // {id, name, user, pass, avatar, tid, comp}
  activityLog:[],  // {icon, text, time}
  penaltyLog:[],   // {sid, name, pts, mot, obs, date, by, byRole}
  roomScoreLog:[]
}
```

**Sempre chamar `saveDB()` após qualquer mutação no DB.**

## Constantes Chave

| Constante | Valor | Significado |
|-----------|-------|-------------|
| `PASS_T` | `16` | Pontos p/ Passe Livre |
| `PEN_PTS` | `5` | Pontos descontados por penalidade |

## Regras de Negócio

- **Quiz**: 8 matérias, 1 pt por acerto, só admin lança pontos oficiais
- **Penalidade**: -5 pts + sempre revoga passe (`pltw=true`), registra `by` e `byRole`
- **Sala Especial**: turmas `grade >= 5` disputam; sessão de pipoca ao atingir 30 pts
- **Passe Livre**: `pts >= 16` ativa; penalidade revoga; coordenador pode revogar/restituir

## Abreviações

| Abrev | Significado |
|-------|-------------|
| `CU` | Current User |
| `DB` | Database |
| `tid` | Turma ID |
| `pts` | Points |
| `pltw` | Pass lost this week |
| `prtw` | Pass regained this week |
| `rp` | Room points |
| `comp` | Componente curricular (professor) |
| `M` suffix | Modal (ex: `penM`, `addPtsM`) |

## CSS

Variáveis de cor: `--v` (violet), `--c` (cyan), `--r` (red), `--a` (amber), `--g` (green), `--iris` (gradient).
Sempre usar `var(--x)` em vez de hex hardcoded.

Classes: `.sc` (stat card), `.sc-v/.sc-c/.sc-r/.sc-a/.sc-g`, `.rr` (ranking row), `.rk1/.rk2/.rk3`, `.tag`, `.btn`, `.btn-iris/.btn-v/.btn-r/.btn-g/.btn-ghost/.btn-a`.

Modais: `showM(id)` / `hideM(id)`. IDs seguem padrão `<purpose>M`.

## Credenciais de Teste

| Role | Usuário | Senha |
|------|---------|-------|
| Estudante | `joao` | `123` |
| Professor | `prof.carlos` | `123` |
| Coordenador | `coord.ana` | `123` |
| Diretor | `diretor` | `123` |

Reset: `window.storage.set('eg-v4', null); location.reload()`

## Diretrizes para IA

1. Ler o arquivo antes de editar — `index.html` tem 1000+ linhas
2. Manter constraint de arquivo único — tudo em `<style>` e `<script>`
3. `saveDB()` após toda mutação no DB
4. Re-renderizar após mudanças de estado (`renderStu()`, `renderDir()`, etc.)
5. UI sempre em pt-BR
6. Sem dependências externas (exceto Google Fonts já existente)

## Git

- Branch de desenvolvimento: `claude/add-claude-documentation-Wf9qU`
- Branch principal: `main`
- Push: `git push -u origin <branch>`
