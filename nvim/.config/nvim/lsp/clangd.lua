-- lsp/clangd.lua
-- Unreal projects need a compile_commands.json at the project root (see gen-clangdb in bin/).
-- Without it clangd has no include paths and flags every UE type and header as an error.
return {
  cmd = {
    "clangd",
    "--background-index",
    "--header-insertion=never",
    "--pch-storage=memory",
    "--query-driver=" .. vim.env.HOME .. "/Downloads/UE_*/**",
    "-j=8",
  },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  root_markers = { "compile_commands.json", ".git", "CMakeLists.txt" },
}
