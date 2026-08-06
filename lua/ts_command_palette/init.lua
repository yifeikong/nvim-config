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
  -- Add personal shortcuts as { "Description", "Ex command", "search tags", "completion type" }.
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
      completion = command.complete,
      completion_arg = command.complete_arg,
      nargs = command.nargs,
    }
  end

  for name, command in pairs(vim.api.nvim_buf_get_commands(0, {})) do
    if name ~= true then
      commands[#commands + 1] = {
        name = name,
        description = command.desc and command.desc ~= "" and command.desc or command.definition or "",
        tags = command.complete or "",
        source = "buffer",
        completion = command.complete,
        completion_arg = command.complete_arg,
        nargs = command.nargs,
      }
    end
  end

  return commands
end

local function custom_commands(config)
  return vim.tbl_map(function(command)
    local description, name, tags, completion = unpack(command)
    return {
      name = name:gsub("^:", ""),
      description = description,
      tags = tags or "",
      source = "custom",
      completion = completion,
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

local function completion_type(entry, config)
  local configured = config.parameter_completions[entry.name]
  if configured then
    return configured
  end

  if entry.completion == "custom" or entry.completion == "customlist" then
    if entry.completion_arg then
      return entry.completion .. "," .. entry.completion_arg
    end
    return nil
  end

  -- Lua callbacks are intentionally opaque in nvim_get_commands(). Neovim's
  -- command line still knows how to invoke them, so use that as the fallback.
  if entry.completion and entry.completion ~= "<Lua function>" then
    return entry.completion
  end
end

local function pick_parameter(entry, completion, opts)
  local command = entry.name
  local ok, parameters = pcall(vim.fn.getcompletion, "", completion)
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

local function continue_command(entry, opts)
  local completion = completion_type(entry, opts)
  if completion then
    pick_parameter(entry, completion, opts)
  else
    vim.api.nvim_feedkeys(":" .. entry.name .. " ", "n", false)
  end
end

local function execute_command(entry, opts)
  -- Commands that declare one or more required arguments should open their
  -- command line even when no picker-compatible completion is available.
  if entry.nargs == "1" or entry.nargs == "+" then
    continue_command(entry, opts)
    return
  end

  local ok, result = pcall(vim.api.nvim_exec2, entry.name, { output = true })
  if not ok then
    notify(result, vim.log.levels.ERROR)
  elseif result.output ~= "" then
    vim.schedule(function()
      notify(result.output)
    end)
  end
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
          value = entry,
          display = string.format(":%-18s %s", entry.name, entry.description),
          ordinal = table.concat({ entry.name, entry.description, entry.tags, entry.source }, " "),
        }
      end,
    }),
    sorter = config.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        execute_command(selection.value, opts)
      end)
      map({ "i", "n" }, "<Tab>", function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        continue_command(selection.value, opts)
      end)
      return true
    end,
  }):find()
end

function M.setup(opts)
  options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

return M
