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
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate", config = function()
      vim.schedule(function()
        require("nvim-treesitter.configs").setup({
          ensure_installed = { "python", "bash" },
          highlight = { enable = true },
        })
      end)
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
})
-- Timeoutlen for key sequences
vim.opt.timeoutlen = 300
-- LSP
vim.lsp.enable("pyright")
vim.lsp.enable("bashls")
vim.lsp.enable("lua_ls")
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
