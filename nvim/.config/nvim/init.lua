vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.shortmess:append("I") -- no intro screen

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)
-- Plugins
require("lazy").setup({
  { "folke/tokyonight.nvim", priority = 1000, config = function()
      -- Dark green-grey "hacker" palette on top of tokyonight, with no blues. NVIM_THEME=tokyonight restores the stock look.
      local hacker = vim.env.NVIM_THEME ~= "tokyonight"
      require("tokyonight").setup({
        style = "night",
        on_colors = function(c)
          if not hacker then return end
          c.bg = "#0e1511"
          c.bg_dark = "#0b110d"
          c.bg_float = "#121b15"
          c.bg_sidebar = "#0b110d"
          c.bg_statusline = "#0b110d"
          c.bg_highlight = "#17241b"
          c.bg_visual = "#1f4d2b"
          c.fg = "#b7ffc4"
          c.fg_dark = "#7fd993"
          c.fg_gutter = "#2a4a33"
          c.comment = "#4f9a63"
          c.border = "#2a4a33"
          c.dark3 = "#3f6b4b"
          c.dark5 = "#6fb383"
          c.terminal_black = "#2a4a33"
          -- every blue and cyan becomes a green or teal-green
          c.blue0 = "#1f6b3a"
          c.blue = "#7ef0a8"
          c.blue1 = "#2fe0a0"
          c.blue2 = "#2fe0a0"
          c.blue5 = "#9cf0b4"
          c.blue6 = "#b4f5c4"
          c.blue7 = "#1f4d2b"
          c.cyan = "#2fe0a0"
          c.teal = "#2fe0a0"
          c.green = "#00ff66"
          c.green1 = "#2fe0a0"
          c.green2 = "#5dff94"
          c.purple = "#c792ea"
          c.magenta = "#ff6bd6"
          c.magenta2 = "#ff6bd6"
          c.orange = "#ffb454"
          c.yellow = "#e6e86a"
          c.red = "#ff5f7a"
          c.red1 = "#ff5f7a"
        end,
      })
      vim.cmd.colorscheme("tokyonight")
      if hacker then
        -- Tokyonight derives many colours (info, todo, git signs, diffs, plugins) before on_colors runs, so shift every
        -- remaining blue or cyan hue to green, in every highlight group, once everything has loaded.
        local function to_hsv(n)
          local r, g, b = math.floor(n / 65536) % 256 / 255, math.floor(n / 256) % 256 / 255, n % 256 / 255
          local mx, mn = math.max(r, g, b), math.min(r, g, b)
          local d = mx - mn
          if d == 0 then return 0, 0, mx end
          local h
          if mx == r then h = ((g - b) / d) % 6 elseif mx == g then h = (b - r) / d + 2 else h = (r - g) / d + 4 end
          return h * 60, d / mx, mx
        end
        local function to_rgb(h, s, v)
          local c = v * s
          local x = c * (1 - math.abs((h / 60) % 2 - 1))
          local m = v - c
          local r, g, b = 0, 0, 0
          if h < 60 then r, g = c, x elseif h < 120 then r, g = x, c elseif h < 180 then g, b = c, x
          elseif h < 240 then g, b = x, c elseif h < 300 then r, b = x, c else r, b = c, x end
          return math.floor((r + m) * 255 + 0.5) * 65536 + math.floor((g + m) * 255 + 0.5) * 256 + math.floor((b + m) * 255 + 0.5)
        end
        local function unblue(n)
          local h, s, v = to_hsv(n)
          if s < 0.12 or h < 170 or h > 270 then return n end
          return to_rgb(h < 215 and 160 or 125, s, v)
        end
        local function unblue_all()
          for name in pairs(vim.api.nvim_get_hl(0, {})) do
            local hl = vim.api.nvim_get_hl(0, { name = name })
            if not hl.link then
              local changed = false
              for _, key in ipairs({ "fg", "bg", "sp" }) do
                if hl[key] then
                  local new = unblue(hl[key])
                  if new ~= hl[key] then hl[key], changed = new, true end
                end
              end
              if changed then vim.api.nvim_set_hl(0, name, hl) end
            end
          end
        end
        unblue_all()
        vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, { callback = unblue_all })
        vim.api.nvim_create_autocmd("User", { pattern = "LazyDone", callback = unblue_all })
      end
  end},
  { "nvim-treesitter/nvim-treesitter", lazy = false, build = ":TSUpdate", config = function()
      require("nvim-treesitter").install({ "python", "bash", "lua", "c", "cpp", "java" })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "python", "sh", "lua", "c", "cpp", "java" },
        callback = function(ev)
          local lang = ev.match == "sh" and "bash" or ev.match
          pcall(vim.treesitter.start, ev.buf, lang)
        end,
      })
  end},
  -- Telescope
  { "nvim-telescope/telescope.nvim", version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require("telescope")
      -- Game features and plugins are symlinks into other Perforce folders, so follow them,
      -- and skip the generated folders that following them would otherwise pull in.
      local generated = { "/Intermediate/", "/Binaries/", "/Saved/", "/DerivedDataCache/", "^Intermediate/", "^Binaries/" }
      -- Binary assets and leftovers that are never what you are looking for in code. <leader>fa searches without this list.
      local junk = {}
      for _, ext in ipairs({
        "png", "jpe?g", "gif", "bmp", "ico", "tga", "dds", "exr", "hdr", "psd", "svg",
        "uasset", "umap", "ubulk", "uexp", "wav", "mp3", "ogg", "mp4", "webm", "mov",
        "ttf", "otf", "pdf", "zip", "tar", "gz", "7z", "dll", "so", "a", "o", "exe", "pdb", "lib",
        "bak", "log", "patch", "user", "tps", "sym", "debug", "SRCINFO",
      }) do
        table.insert(junk, "%." .. ext .. "$")
      end
      telescope.setup({
        defaults = {
          -- Results on the left, preview on the right, using nearly the full editor width
          layout_strategy = "horizontal",
          layout_config = { width = 0.95, height = 0.9, preview_width = 0.55 },
          file_ignore_patterns = vim.list_extend(vim.deepcopy(generated), junk),
        },
        pickers = {
          find_files = { follow = true },
          live_grep = { additional_args = { "--follow" } },
        },
      })
      telescope.load_extension("fzf")

      vim.keymap.set("n", "SS", function()
        require("telescope.builtin").find_files()
      end, { noremap = true, desc = "SS: Telescope find files" })
      vim.keymap.set("n", "<leader>fa", function()
        require("telescope.builtin").find_files({ file_ignore_patterns = generated, prompt_title = "All files" })
      end, { desc = "Find all files, including images and assets" })
      vim.keymap.set("n", "<leader>fg", function()
        require("telescope.builtin").live_grep()
      end, { desc = "Search text in files" })
    end,
  },
  -- File tree on the left (icons need a Nerd Font in the terminal)
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" }, config = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      require("nvim-tree").setup({
        view = { width = 32 },
        filters = { dotfiles = false },
        renderer = { group_empty = true, root_folder_label = ":t", indent_markers = { enable = true } },
        update_focused_file = { enable = true },
        -- nvim-tree maps S to its own search prompt and C to a git-clean filter, which would swallow the SS (Telescope)
        -- and CC (floating terminal) mappings while the tree is focused
        on_attach = function(bufnr)
          local api = require("nvim-tree.api")
          api.config.mappings.default_on_attach(bufnr)
          vim.keymap.del("n", "S", { buffer = bufnr })
          vim.keymap.del("n", "C", { buffer = bufnr })
        end,
      })
      local api = require("nvim-tree.api")
      vim.keymap.set("n", "<leader>e", function() api.tree.toggle({ focus = false }) end, { desc = "Toggle file tree" })
      vim.keymap.set("n", "<leader>E", function() api.tree.open({ find_file = true }) end, { desc = "Reveal file in tree" })
      -- Start with the tree open (focus stays in the editor), unless a file was given
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          if vim.fn.argc() == 0 then
            api.tree.open({ focus = false })
          end
        end,
      })
      -- Quit when the tree is the last window left
      vim.api.nvim_create_autocmd("BufEnter", {
        nested = true,
        callback = function()
          if #vim.api.nvim_list_wins() == 1 and vim.bo.filetype == "NvimTree" then
            vim.cmd("quit")
          end
        end,
      })
  end},
  -- Git hunks, for reviewing what an agent changed
  { "lewis6991/gitsigns.nvim", config = function()
      local gs = require("gitsigns")
      gs.setup({
        on_attach = function(buf)
          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
          end
          map("]h", function() gs.nav_hunk("next") end, "Next hunk")
          map("[h", function() gs.nav_hunk("prev") end, "Previous hunk")
          map("<leader>hp", gs.preview_hunk, "Preview hunk")
          map("<leader>hr", gs.reset_hunk, "Reset hunk")
          map("<leader>hs", gs.stage_hunk, "Stage hunk")
          map("<leader>hd", gs.diffthis, "Diff against index")
          map("<leader>hb", gs.blame_line, "Blame line")
        end,
      })
  end},
  -- Java (jdtls needs a plugin because it requires a per-project workspace dir)
  { "mfussenegger/nvim-jdtls", ft = "java" },
  -- Debugging (DAP), driven by nvim-jdtls for Java and gdb's native DAP mode for C/C++
  { "mfussenegger/nvim-dap", config = function()
      local dap = require("dap")
      dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap" },
      }
      dap.configurations.c = {
        {
          name = "Launch",
          type = "gdb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
        },
      }
      dap.configurations.cpp = dap.configurations.c
  end},
  { "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end,
  },
})
-- Timeoutlen for key sequences
vim.opt.timeoutlen = 300
-- LSP
vim.lsp.enable("pyright")
vim.lsp.enable("bashls")
vim.lsp.enable("lua_ls")
vim.lsp.enable("clangd")
vim.opt.completeopt = { "menuone", "noselect", "popup" }
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    vim.lsp.completion.enable(true, ev.data.client_id, ev.buf, { autotrigger = true })
    local opts = { buffer = ev.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K",  vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
  end,
})
-- DAP (debugger)
vim.keymap.set("n", "<F5>", function() require("dap").continue() end)
vim.keymap.set("n", "<F10>", function() require("dap").step_over() end)
vim.keymap.set("n", "<F11>", function() require("dap").step_into() end)
vim.keymap.set("n", "<F12>", function() require("dap").step_out() end)
vim.keymap.set("n", "<leader>db", function() require("dap").toggle_breakpoint() end)
vim.keymap.set("n", "<leader>du", function() require("dapui").toggle() end)
-- Coding agent in an adjacent tmux pane (see lua/agent.lua)
require("agent").setup()
-- Floating terminal popup (see lua/terminal.lua)
require("terminal").setup()
