-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.neovide_cursor_animation_length = 0

local function check_backspace()
  local col = vim.fn.col(".") - 1
  if col == 0 then
    return true
  end

  return vim.fn.getline("."):sub(col, col):match("%s") ~= nil
end

local function has_lsp_method(bufnr, method)
  return not vim.tbl_isempty(vim.lsp.get_clients({ bufnr = bufnr, method = method }))
end

local function show_documentation()
  if has_lsp_method(0, vim.lsp.protocol.Methods.textDocument_hover) then
    vim.lsp.buf.hover()
    return
  end

  vim.api.nvim_feedkeys("K", "n", false)
end

local function set_lsp_folds(bufnr)
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    vim.wo[win].foldmethod = "expr"
    vim.wo[win].foldexpr = "v:lua.vim.lsp.foldexpr()"
  end
end

local function organize_imports()
  vim.lsp.buf.code_action({
    apply = true,
    context = {
      only = {
        "source.organizeImports",
        "source.organizeImports.ts",
        "source.sortImports",
      },
      diagnostics = vim.diagnostic.get(0),
    },
  })
end

-- Setup lazy.nvim
require("lazy").setup({
  -- automatically check for plugin updates
  checker = {
    -- automatically check for plugin updates
    enabled = true,
    concurrency = nil, ---@type number? set to 1 to check for updates very slowly
    notify = true, -- get a notification when new updates are found
    frequency = 86400 * 60, -- check for updates every 2 months
    check_pinned = false, -- check for pinned packages that can't be updated
  },
  spec = {
    -- add your plugins here
    {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
        "MunifTanjim/nui.nvim",
        -- {"3rd/image.nvim", opts = {}}, -- Optional image support in preview window: See `# Preview Mode` for more information
      },
      lazy = false, -- neo-tree will lazily load itself
      ---@module "neo-tree"
      ---@type neotree.Config?
      opts = {
        enable_git_status = false,
        enable_diagnostics = false,
      }
    },
    {
      'nmac427/guess-indent.nvim',
      config = function() require('guess-indent').setup {} end,
    },
    {
      'nvim-telescope/telescope.nvim', tag = '0.1.8',
      dependencies = { 'nvim-lua/plenary.nvim' }
    },
    {
      "folke/which-key.nvim",
      event = "VeryLazy",
      opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      },
      keys = {
        {
          "<leader>?",
          function()
            require("which-key").show({ global = false })
          end,
          desc = "Buffer Local Keymaps (which-key)",
        },
      },
    },
    {
      "lewis6991/gitsigns.nvim"
    },
    {
      "lukas-reineke/indent-blankline.nvim",
      main = "ibl",
      ---@module "ibl"
      ---@type ibl.config
      opts = {},
    },
    {
      "neanias/everforest-nvim",
      main = "everforest",
      lazy = false,
      priority = 1000,
      opts = {},
    },
    {
      'nvim-lualine/lualine.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' }
    },
    {
      "FabijanZulj/blame.nvim",
      lazy = false, config = function()
        require('blame').setup {
          date_format = "%Y-%m-%d",
          virtual_style = "float",
        }
      end,
    },
    {
      "voldikss/vim-floaterm",
    },
    {
      's1n7ax/nvim-window-picker',
      name = 'window-picker',
      event = 'VeryLazy',
      version = '2.*',
      config = function()
        require'window-picker'.setup()
      end,
    },
    {
      "benomahony/uv.nvim",
      opts = {
        picker_integration = true,
      },
    },
  },

  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
})

require("ts_command_palette").setup()
vim.keymap.set("n", "<leader>p", "<cmd>TSCommandPalette<cr>", {
  silent = true,
  desc = "Command Palette",
})

-- Migrated from ~/.dotfiles/vim/vimrc_base. Keep editor preferences here so
-- legacy mappings and plugin settings cannot override this configuration.
vim.opt.scrolloff = 3
vim.opt.magic = true
vim.opt.cindent = true
vim.opt.cinkeys:remove("0#")
vim.opt.indentkeys:remove("0#")
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.history = 1000
vim.opt.undodir = vim.fn.expand("~/.vim/undodir")
vim.opt.undofile = true

vim.opt.fileencodings = { "ucs-bom", "utf-8", "cp936", "gb18030", "big5", "latin1" }
vim.opt.backupcopy = "yes"

vim.opt.wildmenu = true
vim.opt.wildmode = "list:longest"
vim.opt.wildignore:append({ "*/tmp/*", "*.so", "*.swp", "*.zip", "*.pyc", "*.o" })

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.foldlevel = 99

vim.opt.wrap = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.showmatch = true
vim.opt.hlsearch = true

vim.opt.cmdheight = 1
vim.opt.linebreak = true
vim.opt.cursorline = true
vim.opt.textwidth = 0
vim.opt.wrapmargin = 0
vim.opt.formatoptions:append("m")
vim.opt.formatoptions:append("B")
vim.opt.formatoptions:append("j")
vim.opt.breakat = ""
vim.opt.whichwrap = "b,s"
vim.opt.colorcolumn = "88"
vim.opt.list = true
vim.opt.listchars = {
  tab = "▸ ",
  trail = "·",
  extends = ">",
  precedes = "<",
}

vim.cmd("filetype plugin indent on")
vim.cmd("syntax enable")

local legacy_filetype_group = vim.api.nvim_create_augroup("legacy-filetype-preferences", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = legacy_filetype_group,
  pattern = "go",
  callback = function()
    vim.opt_local.listchars = { tab = "  ", trail = "·", extends = ">", precedes = "<" }
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = legacy_filetype_group,
  pattern = { "yaml", "vue", "javascript", "javascriptreact", "typescript", "typescriptreact" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = legacy_filetype_group,
  pattern = "*.impl",
  command = "setfiletype cpp",
})

vim.api.nvim_create_autocmd("FileType", {
  group = legacy_filetype_group,
  pattern = { "xml", "json" },
  callback = function(args)
    if vim.fn.getfsize(vim.api.nvim_buf_get_name(args.buf)) > 1000000 then
      vim.opt_local.syntax = "OFF"
    end
  end,
})

vim.opt.spell = true
vim.opt.updatetime = 300
vim.opt.signcolumn = "yes"
vim.opt.completeopt = "menuone,popup,fuzzy"
vim.cmd.colorscheme("everforest")

-- local highlight = {
--   "RainbowRed",
--   "RainbowYellow",
--   "RainbowBlue",
--   "RainbowOrange",
--   "RainbowGreen",
--   "RainbowViolet",
--   "RainbowCyan",
-- }
--
-- local hooks = require "ibl.hooks"
-- -- create the highlight groups in the highlight setup hook, so they are reset
-- -- every time the colorscheme changes
-- hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
--   vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
--   vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
--   vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
--   vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
--   vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
--   vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
--   vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
-- end)
--
-- require("ibl").setup { indent = { highlight = highlight } }
-- require("ibl").setup()

-- Ported from nvimrc
vim.keymap.set("n", "<leader>a", "<cmd>Telescope live_grep<cr>", { silent = true, desc = "Live Grep" })
vim.keymap.set("n", "<leader>A", "<cmd>Telescope resume<cr>", { silent = true, desc = "Resume Telescope" })
vim.keymap.set("n", "<C-p>", "<cmd>Telescope find_files<cr>", { silent = true, desc = "Find Files" })
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { silent = true, desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { silent = true, desc = "Help Tags" })
vim.keymap.set("", "<C-n>", "<cmd>Neotree filesystem toggle<cr>", { silent = true, desc = "Toggle Neo-tree" })
vim.keymap.set("n", "<leader>r", "<cmd>Neotree reveal<cr>", { silent = true, desc = "Reveal In Neo-tree" })
vim.keymap.set("n", "<leader>b", "<cmd>BlameToggle window<cr>", { silent = true, desc = "Toggle Blame" })

vim.keymap.set("n", "<C-t><C-c>", "<cmd>TermOpen<cr>", { silent = true, desc = "Open Terminal" })
vim.keymap.set("t", "<C-t><C-c>", "<C-\\><C-n><cmd>TermOpen<cr>", { silent = true, desc = "Open Terminal" })
vim.keymap.set("n", "<C-t><C-p>", "<cmd>FloatermPrev<cr>", { silent = true, desc = "Previous Floaterm" })
vim.keymap.set("t", "<C-t><C-p>", "<C-\\><C-n><cmd>FloatermPrev<cr>", { silent = true, desc = "Previous Floaterm" })
vim.keymap.set("n", "<C-t><C-t>", "<cmd>TermToggle<cr>", { silent = true, desc = "Toggle Terminal" })
vim.keymap.set("t", "<C-t><C-t>", "<C-\\><C-n><cmd>TermToggle<cr>", { silent = true, desc = "Toggle Terminal" })
vim.keymap.set("n", "<C-t><C-n>", "<cmd>FloatermNext<cr>", { silent = true, desc = "Next Floaterm" })
vim.keymap.set("t", "<C-t><C-n>", "<C-\\><C-n><cmd>FloatermNext<cr>", { silent = true, desc = "Next Floaterm" })

vim.keymap.set("", "zz", "<cmd>noautocmd wa<cr>", { silent = true, desc = "Write All Without Autocmds" })
vim.keymap.set("", "ZZ", "<cmd>wa<cr>", { silent = true, desc = "Write All" })
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { silent = true, desc = "Terminal Normal Mode" })

vim.keymap.set("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  end

  if check_backspace() or vim.bo.omnifunc == "" then
    return "<Tab>"
  end

  return "<C-x><C-o>"
end, { expr = true, silent = true, desc = "Next Completion Item" })

vim.keymap.set("i", "<S-Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-p>"
  end

  return "<C-h>"
end, { expr = true, silent = true, desc = "Previous Completion Item" })

vim.keymap.set("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-y>"
  end

  return "<C-g>u<CR>"
end, { expr = true, silent = true, desc = "Confirm Completion" })

vim.api.nvim_create_user_command("TrimWhiteSpace", function()
  local view = vim.fn.winsaveview()
  vim.cmd([[%s/\s\+$//e]])
  vim.fn.winrestview(view)
end, {})

-- Kept from vimrc_base: portable editing mappings. Plugin-specific mappings
-- (BufferLine, Pangu, Isort, Tabularize, and renamer) are intentionally absent.
vim.keymap.set("c", "w!!", "w !sudo tee %")
vim.keymap.set("c", "x!!", "w !sudo tee %<CR><CR>:q!<CR>")

vim.keymap.set("n", "<leader>+", "<cmd>enew<cr>", { silent = true, desc = "New Buffer" })
vim.keymap.set("n", "<leader>j", "<cmd>%!jq<cr>", { silent = true, desc = "Format Buffer With jq" })
vim.keymap.set("n", "<leader>m", "<cmd>TrimWhiteSpace<cr>", { silent = true, desc = "Trim Trailing Whitespace" })
vim.keymap.set("n", "<leader>q", "<cmd>wq<cr>", { silent = true, desc = "Write And Quit" })
vim.keymap.set("n", "<leader>s", "<cmd>set paste!<cr>", { silent = true, desc = "Toggle Paste Mode" })
vim.keymap.set("n", "<leader>S", "<cmd>set spell!<cr>", { silent = true, desc = "Toggle Spell Check" })
vim.keymap.set("n", "<leader>w", "<cmd>wa<cr>", { silent = true, desc = "Write All" })
vim.keymap.set("n", "<leader>n", "<cmd>nohlsearch<cr>", { silent = true, desc = "Clear Search Highlight" })

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("legacy-python-mappings", { clear = true }),
  pattern = "python",
  callback = function(event)
    vim.keymap.set("n", "<leader>B", "oimport ipdb; ipdb.set_trace()<Esc>", {
      buffer = event.buf,
      silent = true,
      desc = "Insert ipdb Breakpoint",
    })
  end,
})

vim.keymap.set("n", "<F3>", ":%s/", { desc = "Substitute In Buffer" })
vim.keymap.set("n", "g<F3>", ":s/", { desc = "Substitute In Line" })
vim.keymap.set("n", "<F12>", ":e ++enc=utf-8<cr>", { silent = true, desc = "Reopen As UTF-8" })
vim.keymap.set({ "n", "x" }, "/", "/\\v", { desc = "Very Magic Search" })
vim.keymap.set("i", "<C-u>", "<Esc>viwUi", { desc = "Uppercase Word" })
vim.keymap.set("n", "<C-]>", "g<C-]>", { desc = "Go To Tag" })
vim.keymap.set("i", "<C-a>", "<Home>")
vim.keymap.set("c", "<C-a>", "<Home>")
vim.keymap.set("x", "<C-a>", "^")
vim.keymap.set("i", "<C-e>", "<End>")
vim.keymap.set("c", "<C-e>", "<End>")
vim.keymap.set("x", "<C-e>", "$")
vim.keymap.set("n", "<C-j>", "5j")
vim.keymap.set("n", "<C-k>", "5k")
vim.keymap.set("c", "<C-j>", "<t_kd>")
vim.keymap.set("c", "<C-k>", "<t_ku>")
vim.keymap.set("n", "q:", ":q")
vim.keymap.set("c", "W", "w")

vim.diagnostic.config({
  severity_sort = true,
  underline = true,
  update_in_insert = false,
  virtual_text = true,
})

vim.lsp.inlay_hint.enable(false)

local lsp_servers = {
  clangd = {
    cmd = { "clangd" },
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    root_markers = {
      ".clangd",
      ".clang-tidy",
      ".clang-format",
      "compile_commands.json",
      "compile_flags.txt",
      ".git",
    },
  },
  cssls = {
    cmd = { "vscode-css-language-server", "--stdio" },
    filetypes = { "css", "scss", "less" },
    root_markers = { "package.json", ".git" },
  },
  dockerls = {
    cmd = { "docker-langserver", "--stdio" },
    filetypes = { "dockerfile" },
    root_markers = { "Dockerfile", ".git" },
  },
  docker_compose_language_service = {
    cmd = { "docker-compose-language-service", "--stdio" },
    filetypes = { "yaml.docker-compose" },
    root_markers = { "docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml", ".git" },
  },
  html = {
    cmd = { "vscode-html-language-server", "--stdio" },
    filetypes = { "html" },
    root_markers = { "package.json", ".git" },
  },
  jsonls = {
    cmd = { "vscode-json-language-server", "--stdio" },
    filetypes = { "json", "jsonc" },
    root_markers = { "package.json", ".git" },
  },
  lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" },
    settings = {
      Lua = {
        diagnostics = {
          globals = { "vim" },
        },
        hint = {
          enable = false,
        },
        workspace = {
          checkThirdParty = false,
        },
      },
    },
  },
  pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
  },
  rust_analyzer = {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_markers = { "Cargo.toml", "rust-project.json", ".git" },
  },
  sourcekit = {
    cmd = { "sourcekit-lsp" },
    filetypes = { "swift", "objc", "objcpp" },
    root_markers = { "Package.swift", "compile_commands.json", ".git" },
  },
  sqlls = {
    cmd = { "sql-language-server", "up", "--method", "stdio" },
    filetypes = { "sql", "mysql", "plsql" },
    root_markers = { ".sqllsrc.json", ".git" },
  },
  tailwindcss = {
    cmd = { "tailwindcss-language-server", "--stdio" },
    filetypes = {
      "astro",
      "css",
      "eruby",
      "heex",
      "html",
      "javascript",
      "javascriptreact",
      "php",
      "svelte",
      "templ",
      "typescript",
      "typescriptreact",
      "vue",
    },
    root_markers = {
      "tailwind.config.js",
      "tailwind.config.cjs",
      "tailwind.config.ts",
      "postcss.config.js",
      "postcss.config.cjs",
      "package.json",
      ".git",
    },
  },
  taplo = {
    cmd = { "taplo", "lsp", "stdio" },
    filetypes = { "toml" },
    root_markers = { "taplo.toml", ".taplo.toml", "Cargo.toml", ".git" },
  },
  ts_ls = {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = {
      "javascript",
      "javascriptreact",
      "javascript.jsx",
      "typescript",
      "typescriptreact",
      "typescript.tsx",
    },
    root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
  },
}

for name, config in pairs(lsp_servers) do
  local executable = config.cmd and config.cmd[1]
  if executable == nil or vim.fn.executable(executable) == 1 then
    vim.lsp.config(name, config)
    vim.lsp.enable(name)
  end
end

local lsp_group = vim.api.nvim_create_augroup("native-lsp-config", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_group,
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client == nil then
      return
    end

    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_completion) then
      vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
    end

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_foldingRange) then
      set_lsp_folds(bufnr)
    end

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_codeLens) then
      local codelens_group = vim.api.nvim_create_augroup("native-lsp-codelens-" .. bufnr, { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
        group = codelens_group,
        buffer = bufnr,
        callback = function()
          vim.lsp.codelens.refresh({ bufnr = bufnr })
        end,
      })
      vim.lsp.codelens.refresh({ bufnr = bufnr })
      map("n", "<leader>cl", vim.lsp.codelens.run, "Run CodeLens")
    end

    map("n", "[g", vim.diagnostic.goto_prev, "Previous Diagnostic")
    map("n", "]g", vim.diagnostic.goto_next, "Next Diagnostic")
    map("n", "gd", vim.lsp.buf.definition, "Go To Definition")
    map("n", "gy", vim.lsp.buf.type_definition, "Go To Type Definition")
    map("n", "gi", vim.lsp.buf.implementation, "Go To Implementation")
    map("n", "gr", function()
      require("telescope.builtin").lsp_references()
    end, "References")
    map("n", "K", show_documentation, "Hover")

    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
    map({ "n", "x" }, "<leader>f", function()
      vim.lsp.buf.format({ async = true })
    end, "Format")
    map({ "n", "x" }, "<leader>A", function()
      vim.lsp.buf.code_action()
    end, "Code Action")
    map("n", "<leader>Ac", function()
      vim.lsp.buf.code_action()
    end, "Code Action At Cursor")
    map("n", "<leader>As", function()
      vim.lsp.buf.code_action({
        context = {
          only = { "source" },
          diagnostics = vim.diagnostic.get(bufnr),
        },
      })
    end, "Source Action")
    map("n", "<leader>qf", function()
      vim.lsp.buf.code_action({
        apply = true,
        context = {
          only = { "quickfix" },
          diagnostics = vim.diagnostic.get(bufnr),
        },
      })
    end, "Quick Fix")
    map("n", "<leader>re", function()
      vim.lsp.buf.code_action({
        context = {
          only = { "refactor" },
          diagnostics = vim.diagnostic.get(bufnr),
        },
      })
    end, "Refactor")
    map({ "n", "x" }, "<leader>r", function()
      vim.lsp.buf.code_action({
        context = {
          only = { "refactor" },
          diagnostics = vim.diagnostic.get(bufnr),
        },
      })
    end, "Refactor Selection")
    map("n", "<leader>ld", function()
      require("telescope.builtin").diagnostics({ bufnr = bufnr })
    end, "Buffer Diagnostics")
    map("n", "<leader>lo", function()
      require("telescope.builtin").lsp_document_symbols()
    end, "Document Symbols")
    map("n", "<leader>ls", function()
      require("telescope.builtin").lsp_dynamic_workspace_symbols()
    end, "Workspace Symbols")
    map("n", "<leader>li", function()
      vim.cmd("checkhealth vim.lsp")
    end, "LSP Health")

    vim.api.nvim_buf_create_user_command(bufnr, "Format", function()
      vim.lsp.buf.format({ async = true, bufnr = bufnr })
    end, {})

    vim.api.nvim_buf_create_user_command(bufnr, "Fold", function()
      set_lsp_folds(bufnr)
      vim.cmd("normal! zx")
    end, { nargs = "?" })

    vim.api.nvim_buf_create_user_command(bufnr, "OR", organize_imports, {})
  end,
})

require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'auto',
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    always_show_tabline = true,
    globalstatus = false,
    refresh = {
      statusline = 100,
      tabline = 100,
      winbar = 100,
    }
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {}
}
