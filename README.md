# dotfiles

Personal Neovim configuration managed with [GNU Stow](https://www.gnu.org/software/stow/).

---

## What this gives you

- Python, Bash, Lua, C/C++, and Java LSP (diagnostics, hover docs, go-to-definition, completion)
- Java and C/C++ debugging (breakpoints, step in/over/out, variable inspection) via **nvim-dap** + **nvim-dap-ui**
- Syntax highlighting via **nvim-treesitter** + **tokyonight** theme
- Plugin management via **lazy.nvim**
- A single-agent workflow: Neovim and a coding agent (Claude Code by default) side by side in tmux, with the agent's edits reloaded in Neovim and reviewed as git hunks
- All config tracked in git and symlinked with Stow

---

## Dependencies

Install these first with pacman:

```bash
sudo pacman -S stow tmux pyright bash-language-server lua-language-server tree-sitter-cli clang jdk-openjdk gdb
```

`jdtls` (the Java language server) and `java-debug` (the Java debug adapter) aren't in the official repos — install them from the AUR:

```bash
paru -S jdtls java-debug
```

`java-debug` builds from source with Maven, so expect it to take a few minutes and pull in a `jdk21-openjdk` build dependency.

- `stow` — symlink manager that connects this repo to `~/.config`
- `tmux` — runs Neovim and the agent side by side (`notify-send`, from `libnotify`, is optional and used for desktop notifications)
- `pyright` — the Python language server
- `bash-language-server` — the Bash language server
- `lua-language-server` — the Lua language server
- `tree-sitter-cli` — required by nvim-treesitter to compile parsers
- `clang` — provides `clangd`, the C/C++ language server
- `gdb` — the C/C++ debugger, driven through `nvim-dap` using its built-in DAP mode (GDB 14+)
- `jdk-openjdk` — Java Development Kit, required to run both `javac` and `jdtls`
- `jdtls` (AUR) — the Java language server, driven through the `nvim-jdtls` plugin
- `java-debug` (AUR) — the Java debug adapter server, driven through `nvim-dap` + `nvim-jdtls`

---

## Install

```bash
git clone git@github.com:SNDesign1/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow nvim tmux kitty bin
```

`tmux`, `kitty` and `bin` are only needed for the agent workflow below. `bin` links `agent-dev` and `agent-notify` into `~/.local/bin`, so that directory needs to be on your `PATH`. `kitty` adds `agent-dev.conf`, a dark green-grey config used only for the agent window (it does not change your normal kitty), and expects a Nerd Font such as MesloLGM Nerd Font Mono for the file-tree icons. It also adds the `HackerGreen` KDE colour scheme and the window icon. To make the window's title bar match (KDE Plasma only), run `agent-dev-titlebar` once; it adds a KWin window rule for the `xrdashboard-nvim` window class in `~/.config/kwinrulesrc`, which this repo does not track.

Then open Neovim — lazy.nvim will automatically install itself and all plugins on first launch, and `nvim-treesitter` will automatically download and compile the Python, Bash, Lua, C, C++, and Java parsers in the background. Give it a few seconds on first launch; syntax highlighting for a given file kicks in as soon as its parser finishes compiling. To add another language later, run `:TSInstall <language>`.

For C/C++, clangd gives full intellisense (types across headers, includes, etc.) only when it can see your build flags. In a project with a `Makefile`/`CMakeLists.txt`, generate a `compile_commands.json` in the project root (e.g. `bear -- make`, or `cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .`) and clangd will pick it up automatically. Without one, clangd still works but falls back to guessed flags, so cross-file/header resolution can be incomplete.

For Java, the first time you open a `.java` file in a project, `jdtls` will index the project into a workspace cache at `~/.cache/nvim/jdtls-workspace/<project-name>/`. Indexing can take a few seconds on first open — that's normal.

Java debugging only activates if `/usr/share/java-debug/com.microsoft.java.debug.plugin.jar` exists (i.e. the `java-debug` AUR package is installed) — `ftplugin/java.lua` checks for it and silently skips debug setup otherwise, so everything else keeps working even without it.

To debug a C/C++ program: compile with debug symbols (`gcc -g -o myprog myprog.c`), open the source in Neovim, set a breakpoint with `<leader>db`, then press `<F5>`. It'll prompt for the path to the compiled executable — point it at `myprog`.

---

## Working with a coding agent

A single-agent setup in the style of the editor-plus-terminal-agent workflow: Neovim on the left, one agent on the right, in the same tmux window. There is no parallel-agent orchestration. You hand work to one agent, read what it did, and decide.

```bash
cd ~/some/project
agent-dev            # nvim (left) + claude (right), one tmux session per directory
AGENT_CMD=opencode agent-dev   # use a different agent
AGENT_WIDTH=30 agent-dev       # agent pane width in percent (default 35)
```

The window is nvim-tree on the left, the editor in the middle and the agent on the right. To open it in its own bare kitty window (no menu bar or toolbar), run `kitty --config ~/.config/kitty/agent-dev.conf --directory <project> agent-dev`, or use a launcher that does the same.

Running `agent-dev` again in the same directory re-attaches to the existing session. If you quit nvim with `:qa` (which closes its pane), running it again recreates the editor pane on the left of the surviving agent pane; the editor and agent panes are found through the tmux pane option `@role` (`editor` / `agent`). Inside tmux, `Alt-h/j/k/l` moves between panes without the prefix.

### Ctrl+Shift+T launcher (KDE Plasma)

`kitty/.local/share/applications/xrdashboard-nvim.desktop` is a launcher with a global shortcut (`X-KDE-Shortcuts=Ctrl+Shift+T`) that opens the bare kitty window running `agent-dev` in the XRDashboard project. Its `Exec` line has the project path and `/home/simeon` written out, because desktop files do not expand `~` or `$HOME`, so edit those paths on another machine or for another project. There is also a "Plain nvim only" action on the launcher's right-click menu. After `stow kitty`, run `kbuildsycoca6` (or log out and in) so Plasma registers the shortcut; check it under System Settings > Shortcuts if `Ctrl+Shift+T` clashes with another binding.

### Hiding the taskbar (KDE Plasma)

To give the agent window the whole screen, set the Plasma panel to hide itself. This is a per-machine Plasma setting that this repo does not track.

In the GUI: right-click an empty spot on the panel, choose **Enter Edit Mode**, click **More Settings...** (or the panel's gear), set **Visibility** to **Auto Hide**, then press **Done**. The panel slides away and returns when the pointer touches the screen edge. **Windows Can Cover** is the gentler option: the panel stays visible except when a window overlaps it.

From a terminal, the same setting through Plasma's scripting interface (first panel only; use `"none"` to turn it back off, or `"windowscover"` for Windows Can Cover):

```bash
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'panels()[0].hiding = "autohide"'
```

### Finding files and text

| Key | What it does |
|---|---|
| `SS` | Telescope: find files (ignores generated folders and binary assets) |
| `<leader>fa` | Find all files, including images and assets |
| `<leader>fg` | Search text in files |

Telescope uses the horizontal layout (results left, preview right) at 95% of the editor width. The file tree opens on start only when nvim is launched with no file argument, and nvim quits when the tree is the last window left.

### Neovim keys (leader is `\`, Neovim's default)

| Key | What it does |
|---|---|
| `<leader>e` | Toggle the file tree (`<leader>E` reveals the current file in it) |
| `<leader>af` | Paste `@path/to/file` into the agent's prompt |
| `<leader>as` (visual) | Paste the selected lines with file and line range |
| `<leader>ad` | Paste this buffer's LSP diagnostics as a list to fix |
| `<leader>ap` | Jump to the agent pane |
| `<leader>ar` | Put every modified or new file in git into the quickfix list (`:cnext` / `:cprev` to step through) |
| `]h` / `[h` | Next / previous changed hunk (gitsigns) |
| `<leader>hp` | Preview the hunk |
| `<leader>hr` / `<leader>hs` | Reset / stage the hunk |
| `<leader>hd` | Diff the buffer against the index |

Text is pasted into the agent's prompt but never submitted, so you read it and press Enter yourself. The agent pane is found through a tmux pane option (`@role=agent`) that `agent-dev` sets, because agents rewrite the pane title. If you start panes by hand and there are exactly two, the other one is used.

### Reviewing what the agent did

Neovim runs `:checktime` on focus, buffer enter and idle, so files the agent edits reload on their own (with a message). Use `<leader>ar` to list changed files, then `]h` and `<leader>hp` to read each hunk, and `<leader>hr` to throw one away.

### Notification when the agent needs you

`agent-notify` shows a tmux message and a desktop notification. To run it when Claude Code finishes a turn, add a hook to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [{ "hooks": [{ "type": "command", "command": "agent-notify 'agent finished'" }] }]
  }
}
```

This repo does not manage that file. Merge the snippet into yours by hand.

---

## How it works (step by step)

### 1. Stow and the dotfiles repo

Rather than keeping config files directly in `~/.config/nvim`, everything lives in `~/dotfiles/nvim/.config/nvim/`. Stow creates a symlink so Neovim still finds the files at the expected path, but they are actually tracked in this git repo. This means every change you make is version controlled and the entire setup can be restored on a new machine with a single `stow nvim` command.

### 2. lazy.nvim (plugin manager)

lazy.nvim is bootstrapped directly in `init.lua` — it clones itself from GitHub the first time Neovim starts if it is not already present. No manual install step required. It manages downloading and updating all plugins declared in the `require("lazy").setup({})` block.

### 3. tokyonight (colourscheme, with a black-and-green "hacker" palette)

The palette is overridden to a dark green-grey with phosphor-green accents and no blues; start Neovim with `NVIM_THEME=tokyonight` to get the stock look. A full truecolour theme that provides colour definitions for all Treesitter highlight groups. Without a theme that supports Treesitter, syntax highlighting appears muted or absent even when the parser is running. `priority = 1000` ensures it loads before anything else. `vim.opt.termguicolors = true` is required to tell Neovim to use the terminal's full RGB colour support.

### 4. nvim-treesitter (syntax highlighting)

Treesitter parses your code into a proper syntax tree rather than using regex patterns. This gives accurate, context-aware highlighting of keywords, classes, functions, types, strings etc. `nvim-treesitter` is on the `main` branch, which is a full rewrite of the plugin with a different API from the old `master` branch (no more `.setup({ ensure_installed, highlight })`). `init.lua` calls `require("nvim-treesitter").install({...})` on startup to fetch/compile any missing parsers with `tree-sitter-cli`, and a `FileType` autocommand calls `vim.treesitter.start()` per buffer to turn highlighting on — Neovim's core treesitter highlighter, not something the plugin enables for you anymore.

### 5. Pyright (Python LSP)

Pyright is a language server — a separate program that understands Python and communicates with Neovim over a protocol called LSP. Neovim 0.11 has a built-in LSP client so no plugin is needed. The file `lsp/pyright.lua` tells Neovim how to start Pyright, which filetypes to attach it to, and how to find the root of a project (looks for `.git`, `pyproject.toml` etc). Without a recognised root directory Pyright runs blind and cannot resolve imports.

### 6. bash-language-server (Bash LSP)

Works the same way as Pyright but for Bash scripts. Provides diagnostics, hover docs, and completion for shell builtins and commands. Configured in `lsp/bashls.lua`. Attaches to `.sh` and `.bash` files. Requires a `.git` folder in the project root to set the root directory correctly.

### 7. lua-language-server (Lua LSP)

Works the same way as the other language servers but for Lua. Configured in `lsp/lua_ls.lua`. Attaches to `.lua` files and is aware of Neovim's LuaJIT runtime, so it understands the `vim.*` API — providing completion, hover docs, and diagnostics across your entire Neovim config. The `workspace.library` setting exposes Neovim's runtime files so the server can resolve built-in globals without false warnings.

### 8. clangd (C/C++ LSP)

Configured in `lsp/clangd.lua`. Attaches to `.c`, `.cpp`, `.objc`, and `.objcpp` files. clangd is also the engine behind clang-based tooling in general, so it gives accurate diagnostics and completion straight from the real compiler frontend rather than a heuristic parser. Its root is detected from `compile_commands.json`, `CMakeLists.txt`, or `.git` — see the note above about generating `compile_commands.json` for full cross-file intellisense.

### 9. jdtls (Java LSP)

Java is handled differently from the other languages because jdtls requires its own per-project workspace directory to store index/cache state — a plain `lsp/*.lua` config isn't enough for that. Instead, `mfussenegger/nvim-jdtls` is pulled in as a plugin (lazy-loaded on the `java` filetype), and `ftplugin/java.lua` runs on every Java buffer: it finds the project root, derives a workspace directory under `~/.cache/nvim/jdtls-workspace/<project-name>/`, and starts/attaches jdtls with `jdtls.start_or_attach()`. Once attached it behaves like any other LSP client — the same `LspAttach` autocmd in `init.lua` wires up its keymaps and completion.

The root is detected from `pom.xml`, `build.gradle`/`build.gradle.kts`, or `.git`; if none of those exist as an ancestor (e.g. a standalone `.java` file with no Maven/Gradle/git project around it), `ftplugin/java.lua` falls back to the buffer's own directory as the root instead of skipping jdtls entirely — so completion, diagnostics, and hover still work outside a real project, just without cross-module awareness.

### 10. Built-in completion

Neovim 0.11 includes a built-in completion engine. `vim.lsp.completion.enable()` activates it. Completion triggers automatically on characters declared by the language server — for Pyright this is `.`, `[`, `"` and `'`. Confirm a completion with `<C-y>`.

### 11. nvim-dap + nvim-dap-ui (debugging)

`nvim-dap` is a generic Debug Adapter Protocol client — it doesn't know anything about any particular language by itself, it just speaks the DAP wire protocol to whatever debug adapter process it's pointed at. `nvim-dap-ui` sits on top of it to render the running state (variables, call stack, breakpoints, REPL) as sidebar panels instead of one-off commands; it opens automatically when a debug session starts and closes when it ends, via the `dap.listeners` hooks in `init.lua`.

For Java, the adapter is the `java-debug` bundle (`com.microsoft.java.debug.plugin.jar`) — `ftplugin/java.lua` registers it with jdtls via `init_options.bundles`, and once jdtls attaches, `jdtls.setup_dap()` registers a `"java"` adapter with `nvim-dap` that proxies through the running jdtls connection. Java debugging needs no separate adapter process of its own; it rides on the same jdtls connection.

For C/C++, GDB (14+) has its own built-in DAP server, so `nvim-dap` just spawns `gdb --interpreter=dap` directly (registered as the `"gdb"` adapter in `init.lua`) — no separate adapter package needed. `dap.configurations.c`/`.cpp` define a "Launch" config that prompts for the path to a compiled executable each time you start debugging with `<F5>`, since (unlike Java, which jdtls already knows how to build/run) there's no build system integration telling `nvim-dap` what binary to run.

---

## Keymaps

These are active whenever an LSP server is attached to a buffer:

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `K` | Hover documentation |
| `gr` | Find references |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |

Debugger keymaps (global; work for C/C++ out of the box, need `java-debug` installed for Java):

| Key | Action |
|-----|--------|
| `<F5>` | Continue / start debugging |
| `<F10>` | Step over |
| `<F11>` | Step into |
| `<F12>` | Step out |
| `<leader>db` | Toggle breakpoint |
| `<leader>du` | Toggle the dap-ui panel |

---

## File structure

```
~/dotfiles/
├── nvim/.config/nvim/
│   ├── init.lua                 ← main config
│   ├── lua/agent.lua            ← bridge to the agent tmux pane
│   ├── lsp/
│   │   ├── pyright.lua          ← Python language server config
│   │   ├── bashls.lua           ← Bash language server config
│   │   ├── lua_ls.lua           ← Lua language server config
│   │   └── clangd.lua           ← C/C++ language server config
│   └── ftplugin/java.lua        ← starts jdtls (Java) per project
├── tmux/.config/tmux/tmux.conf  ← pane keys for the agent workflow
├── bin/.local/bin/              ← agent-dev, agent-dev-titlebar, agent-notify
└── kitty/
    ├── .config/kitty/agent-dev.conf
    └── .local/share/
        ├── applications/xrdashboard-nvim.desktop  ← Ctrl+Shift+T launcher
        ├── color-schemes/HackerGreen.colors
        └── icons/hicolor/scalable/apps/agent-dev.svg
```
