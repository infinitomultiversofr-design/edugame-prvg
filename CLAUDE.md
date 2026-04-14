# CLAUDE.md — EduGame PRVG

Guidance for AI assistants working on this repository.

## Project Overview

**EduGame PRVG** is a browser-based educational gamification platform for Brazilian schools. The entire application lives in a single self-contained HTML file (`index.html`) with no external dependencies, no build system, and no package manager.

- **Language**: Brazilian Portuguese (pt-BR) — all UI text, variable names, and data are in Portuguese
- **Stack**: Vanilla HTML5 / CSS3 / JavaScript (ES6+)
- **Persistence**: Browser storage API (`window.storage.get/set('eg-v4')`)
- **Deployment**: Serve `index.html` from any static host; works from `file://` as well

---

## Repository Structure

```
edugame-prvg/
├── index.html   # Entire application (HTML + embedded CSS + embedded JS)
└── CLAUDE.md    # This file
```

There are no configuration files, build scripts, test suites, or external assets.

---

## Architecture

### Single-File SPA

All HTML, CSS, and JavaScript are inlined in `index.html`. The application is a single-page app driven by DOM mutations — sections are shown/hidden rather than navigated to.

### Boot Flow

```
window load → boot() → loadDB() → renderWelcome() → [User logs in] → showDash()
```

`loadDB()` reads from `window.storage`; if no saved data exists, `seed()` generates default test data.

### Role-Based Access Control

Three user roles, each with its own dashboard section:

| Role | Portuguese | DOM Section | Key Permissions |
|------|-----------|-------------|-----------------|
| Student | Estudante | `#stuDash` | View own stats, take quizzes, see rankings |
| Coordinator | Coordenador | `#coDash` | Manage students in assigned classrooms, award points, issue penalties |
| Director | Diretor | `#dirDash` | Full system view, analytics, manage all users/classes |

The global `CU` (Current User) object carries `{role, ...userData}` after login.

### Data Model (Global `DB` Object)

```javascript
DB = {
  turmas: [],       // Classrooms: {id, name, shift, rp}
  students: [],     // {id, name, user, pass, avatar, tid, pts, wp, lost, wq, hadPass, pltw, prtw}
  coordinators: [], // {id, name, user, pass, avatar}
  activityLog: [],  // {icon, text, time}
  penaltyLog: [],   // {sid, name, pts, mot, obs, date}
  roomScoreLog: []  // Classroom score history entries
}
```

`saveDB()` must be called after every mutation to persist changes.

---

## Key Constants (top of `<script>`)

| Constant | Value | Meaning |
|----------|-------|---------|
| `PASS_T` | `16` | Points needed to earn a free pass |
| `PEN_PTS` | `5` | Points deducted per penalty |
| `SUBJECTS` | array | 8 quiz subjects |
| `QS` | array | Quiz question bank |
| `BADGES` | array | 8 achievement badge definitions |
| `AVTS` | array | Available avatar emojis |

---

## Code Organization

The JavaScript is divided into sections separated by ASCII banners:

```
// ══ [SECTION NAME] ═══════════════════════════════════════════
```

Sections in order:
1. Constants
2. DB init & storage helpers (`loadDB`, `saveDB`, `seed`)
3. Helpers (uid generation, rankings, pass calculations)
4. UI utilities (modals: `openM`/`closeM`, toasts)
5. Auth (`handleLogin`, `logout`, `renderHdr`)
6. Welcome page (`renderWelcome`)
7. Student dashboard (`renderStu` and tab renderers)
8. Quiz system (`openQuiz`, scoring logic)
9. Coordinator dashboard (`renderCo`)
10. Director dashboard (`renderDir` and sub-tab renderers)
11. CRUD operations (`createTurma`, `createStu`, `createCoord`)
12. Tab switching (`switchTab`)
13. Boot / initialization (`boot`)

---

## Naming Conventions

### JavaScript

- **Functions**: camelCase — `renderStu()`, `handleLogin()`, `openQuiz()`
- **Global state**: short uppercase — `DB` (database), `CU` (current user), `aQS` (active quiz)
- **DOM selectors**: match HTML IDs directly — `document.getElementById('stuDash')`

### Common Abbreviations

| Abbreviation | Meaning |
|-------------|---------|
| `CU` | Current User |
| `DB` | Database |
| `st` / `stu` | Student |
| `co` | Coordinator |
| `dir` | Director |
| `pts` | Points |
| `rp` | Room Points (classroom score) |
| `wp` | Quiz wins |
| `wq` | Weekly quiz completed flag |
| `tid` | Turma (classroom) ID |
| `mot` | Motivo (reason/motive) |
| `obs` | Observação (observation/note) |
| `pltw` | Pass lost this week |
| `prtw` | Pass regained this week |
| `hadPass` | Had pass flag |
| `M` suffix | Modal (e.g., `addPtsM`, `loginM`) |

### CSS

- **Utility classes**: short, single-purpose — `.rr` (ranking row), `.rk1/.rk2/.rk3` (rank medals), `.sc` (stat card)
- **Color variants**: suffix letter — `.sc-v` (violet), `.sc-c` (cyan), `.sc-r` (red), `.sc-a` (amber), `.sc-g` (green)
- **Buttons**: `.btn`, `.btn-iris`, `.btn-v`, `.btn-r`, `.btn-g`, `.btn-ghost`, `.btn-sm`
- **Tags/badges**: `.tag`, `.tag-v`, `.tag-c`, etc.

### CSS Variables

```css
--v: #7C3AFF    /* violet (primary) */
--c: #00DEFF    /* cyan */
--r: #FF2D6B    /* red */
--a: #FFB800    /* amber */
--g: #00E5A0    /* green */
--iris: linear-gradient(...)  /* multi-color accent gradient */
--vd / --cd / --rd / --ad / --gd  /* dim/alpha variants of each color */
--gv / --gc / --gr / --ga / --gg  /* glow box-shadow variants */
```

---

## Development Workflow

### Running the Application

No build step required:

```bash
# Option 1: open directly in browser
open index.html

# Option 2: serve with any static server
python3 -m http.server 8080
# then visit http://localhost:8080
```

### Test Credentials (seeded by default)

| Role | Username | Password |
|------|----------|----------|
| Student | `joao` | `123` |
| Coordinator | `coord.ana` | `123` |
| Director | `diretor` | `123` |

### Resetting Data

Open the browser console and run:
```javascript
window.storage.set('eg-v4', null); location.reload();
```

This clears stored data and triggers a fresh `seed()` on next boot.

---

## Editing Guidelines for AI Assistants

1. **Read before editing** — `index.html` is 795+ lines; always read the relevant section before modifying it.

2. **Maintain the single-file constraint** — Do not split into multiple files unless explicitly asked. All styles go in `<style>`, all scripts in `<script>`.

3. **Call `saveDB()` after mutations** — Any function that changes `DB` must call `saveDB()` before returning.

4. **Re-render after state changes** — Dashboard sections are rendered imperatively. After a data change, call the appropriate render function (e.g., `renderStu()`, `renderDir()`) to update the UI.

5. **Follow existing abbreviation style** — New fields on student/coordinator/turma objects should use the same terse naming (2–4 char abbreviations) to stay consistent.

6. **Portuguese UI text** — All user-facing strings must be in Brazilian Portuguese.

7. **No external dependencies** — Do not introduce CDN links (other than the existing Google Fonts import), npm packages, or external scripts.

8. **CSS variables for color** — Always use the CSS custom properties (e.g., `var(--v)`) rather than hardcoded hex values when adding styled elements.

9. **Section banners** — When adding a new logical group of functions, add an ASCII section banner matching the existing style.

10. **Modal pattern** — Use `openM(id)` / `closeM(id)` for showing/hiding modals. Modal IDs follow the `<purpose>M` pattern (e.g., `addPtsM`).

---

## Gamification Logic Summary

- **Pass system**: Students accumulate points (`pts`). When `pts >= PASS_T` (16), they earn a "free pass" (`hadPass = true`). Coordinators can revoke it (`pltw++`) or reinstate it (`prtw++`).
- **Penalties**: Cost the student `PEN_PTS` (5) points; logged in `DB.penaltyLog`.
- **Weekly quiz**: Each student may complete one quiz per week (`wq` flag). Correct answers award points; wins tracked in `wp`.
- **Room points**: Classroom-level score (`turma.rp`) used for classroom rankings, updated by coordinator actions.
- **Badges**: Awarded automatically based on milestones (point thresholds, quiz wins, etc.), defined in the `BADGES` constant.

---

## Git

- **Development branch**: `claude/add-claude-documentation-Wf9qU`
- **Main branch**: `main`
- Commit messages should be concise and in English.
- Push with: `git push -u origin <branch-name>`
