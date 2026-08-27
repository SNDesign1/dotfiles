# dotfiles

Personal Neovim configuration managed with [GNU Stow](https://www.gnu.org/software/stow/).

---

## What this gives you

- Python, Bash, Lua, C/C++, and Java LSP (diagnostics, hover docs, go-to-definition, completion)
- Syntax highlighting via **nvim-treesitter** + **tokyonight** theme
- Plugin management via **lazy.nvim**
- All config tracked in git and symlinked with Stow

---

## Dependencies

Install these first with pacman:

```bash
sudo pacman -S stow pyright bash-language-server lua-language-server tree-sitter-cli clang jdk-openjdk
```

`jdtls` (the Java language server) isn't in the official repos — install it from the AUR:

```bash
paru -S jdtls
```

- `stow` — symlink manager that connects this repo to `~/.config`
- `pyright` — the Python language server
- `bash-language-server` — the Bash language server
- `lua-language-server` — the Lua language server
- `tree-sitter-cli` — required by nvim-treesitter to compile parsers
- `clang` — provides `clangd`, the C/C++ language server
- `jdk-openjdk` — Java Development Kit, required to run both `javac` and `jdtls`
- `jdtls` (AUR) — the Java language server, driven through the `nvim-jdtls` plugin

---

## Install

```bash
git clone git@github.com:SNDesign1/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow nvim
```

Then open Neovim — lazy.nvim will automatically install itself and all plugins on first launch, and `nvim-treesitter` will automatically download and compile the Python, Bash, Lua, C, C++, and Java parsers in the background. Give it a few seconds on first launch; syntax highlighting for a given file kicks in as soon as its parser finishes compiling. To add another language later, run `:TSInstall <language>`.

For C/C++, clangd gives full intellisense (types across headers, includes, etc.) only when it can see your build flags. In a project with a `Makefile`/`CMakeLists.txt`, generate a `compile_commands.json` in the project root (e.g. `bear -- make`, or `cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .`) and clangd will pick it up automatically. Without one, clangd still works but falls back to guessed flags, so cross-file/header resolution can be incomplete.

For Java, the first time you open a `.java` file in a project, `jdtls` will index the project into a workspace cache at `~/.cache/nvim/jdtls-workspace/<project-name>/`. Indexing can take a few seconds on first open — that's normal.

---

## How it works (step by step)

### 1. Stow and the dotfiles repo

Rather than keeping config files directly in `~/.config/nvim`, everything lives in `~/dotfiles/nvim/.config/nvim/`. Stow creates a symlink so Neovim still finds the files at the expected path, but they are actually tracked in this git repo. This means every change you make is version controlled and the entire setup can be restored on a new machine with a single `stow nvim` command.

### 2. lazy.nvim (plugin manager)

lazy.nvim is bootstrapped directly in `init.lua` — it clones itself from GitHub the first time Neovim starts if it is not already present. No manual install step required. It manages downloading and updating all plugins declared in the `require("lazy").setup({})` block.

### 3. tokyonight (colourscheme)

A full truecolour theme that provides colour definitions for all Treesitter highlight groups. Without a theme that supports Treesitter, syntax highlighting appears muted or absent even when the parser is running. `priority = 1000` ensures it loads before anything else. `vim.opt.termguicolors = true` is required to tell Neovim to use the terminal's full RGB colour support.

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

### 10. Built-in completion

Neovim 0.11 includes a built-in completion engine. `vim.lsp.completion.enable()` activates it. Completion triggers automatically on characters declared by the language server — for Pyright this is `.`, `[`, `"` and `'`. Confirm a completion with `<C-y>`.

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

---

## File structure

```
~/dotfiles/
└── nvim/
    └── .config/
        └── nvim/
            ├── init.lua         ← main config
            ├── lsp/
            │   ├── pyright.lua  ← Python language server config
            │   ├── bashls.lua   ← Bash language server config
            │   ├── lua_ls.lua   ← Lua language server config
            │   └── clangd.lua   ← C/C++ language server config
            └── ftplugin/
                └── java.lua     ← starts jdtls (Java) per project
```
