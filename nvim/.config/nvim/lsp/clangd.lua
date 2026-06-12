-- lsp/clangd.lua
return {
  cmd = { "clangd" },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  root_markers = { ".git", "compile_commands.json", "CMakeLists.txt" },
}
