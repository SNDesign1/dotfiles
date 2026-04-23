# dotfiles

Personal Neovim configuration managed with [GNU Stow](https://www.gnu.org/software/stow/).

---

## What this gives you

- Python and Bash LSP (diagnostics, hover docs, go-to-definition, completion on `.`)
- Syntax highlighting via **nvim-treesitter** + **tokyonight** theme
- Plugin management via **lazy.nvim**
- All config tracked in git and symlinked with Stow

---

## Dependencies

Install these first with pacman:

```bash
sudo pacman -S stow pyright bash-language-server tree-sitter-cli
```

- `stow` — symlink manager that connects this repo to `~/.config`
- `pyright` — the Python language server
- `bash-language-server` — the Bash language server
- `tree-sitter-cli` — required by nvim-treesitter to compile parsers

---

## Install

```bash
git clone git@github.com:SNDesign1/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow nvim
```

Then open Neovim — lazy.nvim will automatically install itself and all plugins on first launch.

Once inside Neovim, install the Treesitter parsers:

```
:TSInstall python
:TSInstall bash
```

Restart Neovim and syntax highlighting will be active.

---

## How it works (step by step)

### 1. Stow and the dotfiles repo

Rather than keeping config files directly in `~/.config/nvim`, everything lives in `~/dotfiles/nvim/.config/nvim/`. Stow creates a symlink so Neovim still finds the files at the expected path, but they are actually tracked in this git repo. This means every change you make is version controlled and the entire setup can be restored on a new machine with a single `stow nvim` command.

### 2. lazy.nvim (plugin manager)

lazy.nvim is bootstrapped directly in `init.lua` — it clones itself from GitHub the first time Neovim starts if it is not already present. No manual install step required. It manages downloading and updating all plugins declared in the `require("lazy").setup({})` block.

### 3. tokyonight (colourscheme)

A full truecolour theme that provides colour definitions for all Treesitter highlight groups. Without a theme that supports Treesitter, syntax highlighting appears muted or absent even when the parser is running. `priority = 1000` ensures it loads before anything else. `vim.opt.termguicolors = true` is required to tell Neovim to use the terminal's full RGB colour support.

### 4. nvim-treesitter (syntax highlighting)

Treesitter parses your code into a proper syntax tree rather than using regex patterns. This gives accurate, context-aware highlighting of keywords, classes, functions, types, strings etc. The plugin manages downloading and compiling language parsers. Parsers must be installed separately with `:TSInstall <language>` because they are compiled at install time using `tree-sitter-cli`.

### 5. Pyright (Python LSP)

Pyright is a language server — a separate program that understands Python and communicates with Neovim over a protocol called LSP. Neovim 0.11 has a built-in LSP client so no plugin is needed. The file `lsp/pyright.lua` tells Neovim how to start Pyright, which filetypes to attach it to, and how to find the root of a project (looks for `.git`, `pyproject.toml` etc). Without a recognised root directory Pyright runs blind and cannot resolve imports.

### 6. bash-language-server (Bash LSP)

Works the same way as Pyright but for Bash scripts. Provides diagnostics, hover docs, and completion for shell builtins and commands. Configured in `lsp/bashls.lua`. Attaches to `.sh` and `.bash` files. Requires a `.git` folder in the project root to set the root directory correctly.

### 7. Built-in completion

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
            ├── init.lua        ← main config
            └── lsp/
                ├── pyright.lua ← Python language server config
                └── bashls.lua  ← Bash language server config
```
