if vim.g.loaded_ts_command_palette then
  return
end
vim.g.loaded_ts_command_palette = true

vim.api.nvim_create_user_command("TSCommandPalette", function(command)
  require("ts_command_palette").open({ default_text = command.args })
end, {
  desc = "Show configured commands in Telescope",
  nargs = "?",
})
