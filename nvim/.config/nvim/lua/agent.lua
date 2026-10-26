-- Bridge between Neovim and a coding agent running in an adjacent tmux pane (see bin/agent-dev).
-- Text is pasted into the agent's prompt but never submitted, so you read it and press Enter yourself.
local M = {}

local function tmux(args, input)
  local res = vim.system(vim.list_extend({ "tmux" }, args), { text = true, stdin = input }):wait()
  return res.code == 0, vim.trim(res.stdout or "")
end

-- The agent pane is the one in this window with the pane option @role=agent, set by agent-dev.
-- With only two panes, the other pane is assumed to be the agent.
local function agent_pane()
  if not vim.env.TMUX then
    return nil
  end
  local ok, out = tmux({ "list-panes", "-t", vim.env.TMUX_PANE, "-F", "#{pane_id} #{@role}" })
  if not ok then
    return nil
  end
  local others = {}
  for line in out:gmatch("[^\n]+") do
    local id, role = line:match("^(%S+)%s*(.*)$")
    if role == "agent" then
      return id
    elseif id ~= vim.env.TMUX_PANE then
      table.insert(others, id)
    end
  end
  return #others == 1 and others[1] or nil
end

local function send(text, focus)
  local pane = agent_pane()
  if not pane then
    vim.notify("No agent pane found. Start one with agent-dev.", vim.log.levels.WARN)
    return
  end
  tmux({ "load-buffer", "-b", "nvim-agent", "-" }, text)
  tmux({ "paste-buffer", "-p", "-d", "-b", "nvim-agent", "-t", pane })
  if focus ~= false then
    tmux({ "select-pane", "-t", pane })
  end
end

local function relpath(buf)
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf or 0), ":.")
end

function M.send_file()
  send("@" .. relpath() .. " ")
end

function M.send_selection()
  local a, b = vim.fn.line("v"), vim.fn.line(".")
  local first, last = math.min(a, b), math.max(a, b)
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  send(string.format("@%s:%d-%d\n```%s\n%s\n```\n", relpath(), first, last, vim.bo.filetype, table.concat(lines, "\n")))
end

function M.send_diagnostics()
  local diags = vim.diagnostic.get(0)
  if #diags == 0 then
    vim.notify("No diagnostics in this buffer")
    return
  end
  local severity = { "error", "warning", "info", "hint" }
  local out = { "Fix these diagnostics in " .. relpath() .. ":" }
  for _, d in ipairs(diags) do
    table.insert(out, string.format("- line %d (%s): %s", d.lnum + 1, severity[d.severity], d.message))
  end
  send(table.concat(out, "\n") .. "\n")
end

function M.focus()
  local pane = agent_pane()
  if pane then
    tmux({ "select-pane", "-t", pane })
  else
    vim.notify("No agent pane found. Start one with agent-dev.", vim.log.levels.WARN)
  end
end

-- Put every file the agent changed or created into the quickfix list, to step through with ]q and review with gitsigns.
function M.review()
  local res = vim.system({ "git", "ls-files", "--modified", "--others", "--exclude-standard" }, { text = true }):wait()
  if res.code ~= 0 then
    vim.notify("Not in a git repository", vim.log.levels.WARN)
    return
  end
  local items = {}
  for file in res.stdout:gmatch("[^\n]+") do
    table.insert(items, { filename = file, lnum = 1 })
  end
  if #items == 0 then
    vim.notify("No changed files")
    return
  end
  vim.fn.setqflist({}, " ", { title = "Changed files", items = items })
  vim.cmd("copen")
end

function M.setup()
  -- Pick up edits the agent makes on disk
  vim.opt.autoread = true
  vim.opt.updatetime = 500
  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "TermLeave" }, {
    callback = function()
      if vim.fn.mode() ~= "c" then
        vim.cmd("checktime")
      end
    end,
  })
  vim.api.nvim_create_autocmd("FileChangedShellPost", {
    callback = function(ev)
      vim.notify("Reloaded " .. vim.fn.fnamemodify(ev.file, ":.") .. " (changed on disk)")
    end,
  })

  vim.keymap.set("n", "<leader>af", M.send_file, { desc = "Agent: send file reference" })
  vim.keymap.set("x", "<leader>as", M.send_selection, { desc = "Agent: send selection" })
  vim.keymap.set("n", "<leader>ad", M.send_diagnostics, { desc = "Agent: send diagnostics" })
  vim.keymap.set("n", "<leader>ap", M.focus, { desc = "Agent: focus pane" })
  vim.keymap.set("n", "<leader>ar", M.review, { desc = "Agent: list changed files" })
end

return M
