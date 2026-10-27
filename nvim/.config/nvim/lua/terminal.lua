-- Floating terminal, toggled like a Telescope popup. The shell keeps running while hidden.
local M = {}

local buf, win

local function open()
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    buf = vim.api.nvim_create_buf(false, true)
  end
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
  })
  if vim.bo[buf].buftype ~= "terminal" then
    vim.fn.jobstart(vim.o.shell, { term = true })
    vim.bo[buf].bufhidden = "hide"
    -- Shell exited: drop the buffer so the next toggle starts a fresh one.
    vim.api.nvim_create_autocmd("TermClose", {
      buffer = buf,
      once = true,
      callback = function()
        vim.schedule(function()
          if win and vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
          if buf and vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
          buf, win = nil, nil
        end)
      end,
    })
  end
  vim.cmd("startinsert")
end

function M.toggle()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_hide(win)
    win = nil
  else
    open()
  end
end

function M.setup()
  vim.keymap.set("n", "CC", M.toggle, { desc = "Toggle floating terminal" })
  vim.keymap.set("t", "<C-t>", M.toggle, { desc = "Hide floating terminal" })
  vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Terminal normal mode" })
end

return M
