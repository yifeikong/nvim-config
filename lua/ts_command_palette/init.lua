local M = {}

local defaults = {
  title = "Command Palette",
  include_builtin_commands = true,
  include_user_commands = true,
  parameter_completions = {
    colo = "color",
    colorscheme = "color",
    h = "help",
    help = "help",
    se = "option",
    set = "option",
    setg = "option",
    setglobal = "option",
    setl = "option",
    setlocal = "option",
  },
  -- Add personal shortcuts as { "Description", "Ex command", "search tags" }.
  commands = {},
}

local options = vim.deepcopy(defaults)

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = options.title })
end

local function builtin_commands()
  local filename = vim.fs.joinpath(vim.env.VIMRUNTIME, "doc", "index.txt")
  local file, err = io.open(filename, "r")
  if not file then
    notify(("Could not read Neovim's command index: %s"):format(err), vim.log.levels.WARN)
    return {}
  end

  local commands, seen = {}, {}
  for line in file:lines() do
    local tags, syntax, description = line:match("^|:([^|]+)|%s+(:[^%s]+)%s+(.+)$")
    local name = syntax and syntax:match("^:([%a]+)")

    if name and not seen[name] then
      commands[#commands + 1] = {
        name = name,
        description = description,
        tags = tags,
        source = "builtin",
      }
      seen[name] = true
    end
  end
  file:close()

  return commands
end

local function user_commands()
  local commands = {}

  for name, command in pairs(vim.api.nvim_get_commands({})) do
    commands[#commands + 1] = {
      name = name,
      description = command.desc and command.desc ~= "" and command.desc or command.definition or "",
      tags = command.complete or "",
      source = "user",
    }
  end

  for name, command in pairs(vim.api.nvim_buf_get_commands(0, {})) do
    if name ~= true then
      commands[#commands + 1] = {
        name = name,
        description = command.desc and command.desc ~= "" and command.desc or command.definition or "",
        tags = command.complete or "",
        source = "buffer",
      }
    end
  end

  return commands
end

local function custom_commands(config)
  return vim.tbl_map(function(command)
    local description, name, tags = unpack(command)
    return {
      name = name:gsub("^:", ""),
      description = description,
      tags = tags or "",
      source = "custom",
    }
  end, config.commands)
end

local function command_entries(config)
  local entries, seen = {}, {}
  local sources = {}

  if config.include_builtin_commands then
    sources[#sources + 1] = builtin_commands()
  end
  if config.include_user_commands then
    sources[#sources + 1] = user_commands()
  end
  sources[#sources + 1] = custom_commands(config)

  -- Later sources override earlier ones, so custom commands win over built-ins.
  for _, source in ipairs(sources) do
    for _, entry in ipairs(source) do
      if seen[entry.name] then
        entries[seen[entry.name]] = entry
      else
        entries[#entries + 1] = entry
        seen[entry.name] = #entries
      end
    end
  end

  return entries
end

local function pick_parameter(command, completion_type, opts)
  local ok, parameters = pcall(vim.fn.getcompletion, "", completion_type)
  if not ok or #parameters == 0 then
    vim.api.nvim_feedkeys(":" .. command .. " ", "n", false)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local config = require("telescope.config").values

  pickers.new(opts, {
    prompt_title = ":" .. command .. " argument",
    finder = finders.new_table({ results = parameters }),
    sorter = config.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        vim.cmd({ cmd = command, args = { selection.value } })
      end)
      return true
    end,
  }):find()
end

function M.open(opts)
  opts = vim.tbl_deep_extend("force", {}, options, opts or {})
  local entries = command_entries(opts)
  if #entries == 0 then
    notify("No commands are available.", vim.log.levels.WARN)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local config = require("telescope.config").values

  pickers.new(opts, {
    prompt_title = opts.title,
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry.name,
          display = string.format(":%-18s %s", entry.name, entry.description),
          ordinal = table.concat({ entry.name, entry.description, entry.tags, entry.source }, " "),
        }
      end,
    }),
    sorter = config.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        local completion_type = opts.parameter_completions[selection.value]
        if completion_type then
          pick_parameter(selection.value, completion_type, opts)
        else
          vim.api.nvim_feedkeys(":" .. selection.value .. " ", "n", false)
        end
      end)
      return true
    end,
  }):find()
end

function M.setup(opts)
  options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

return M
