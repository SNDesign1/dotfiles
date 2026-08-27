vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.termguicolors = true

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)
-- Plugins
require("lazy").setup({
  { "folke/tokyonight.nvim", priority = 1000, config = function()
      require("tokyonight").setup({ style = "night" })
      vim.cmd.colorscheme("tokyonight")
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
      telescope.setup({})
      telescope.load_extension("fzf")

      vim.keymap.set("n", "SS", function()
        require("telescope.builtin").find_files()
      end, { noremap = true, desc = "SS: Telescope find files" })
    end,
  },
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
