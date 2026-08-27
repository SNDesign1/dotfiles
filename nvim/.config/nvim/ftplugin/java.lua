local jdtls = require("jdtls")

local root_dir = jdtls.setup.find_root({ "pom.xml", "build.gradle", "build.gradle.kts", ".git" })
if not root_dir then
  return
end

local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls-workspace/" .. project_name

local bundles = {}
local debug_jar = "/usr/share/java-debug/com.microsoft.java.debug.plugin.jar"
if vim.fn.filereadable(debug_jar) == 1 then
  table.insert(bundles, debug_jar)
end

jdtls.start_or_attach({
  cmd = { "jdtls", "-data", workspace_dir },
  root_dir = root_dir,
  settings = {
    java = {
      signatureHelp = { enabled = true },
      completion = { favoriteStaticMembers = {} },
    },
  },
  init_options = {
    bundles = bundles,
  },
  on_attach = function()
    jdtls.setup_dap({ hotcodereplace = "auto" })
  end,
})
