local vite_config_names = {
  'vite.config.js',
  'vite.config.ts',
  'vite.config.mjs',
  'vite.config.mts',
}

local formatter_configs = {
  'biome.json',
  'biome.jsonc',
  'oxc.config.json',
  '.oxc.json',
  '.prettierrc',
  '.prettierrc.json',
  '.prettierrc.yml',
  '.prettierrc.yaml',
  '.prettierrc.js',
  '.prettierrc.mjs',
  '.prettierrc.cjs',
  'prettier.config.js',
  'prettier.config.mjs',
  'prettier.config.cjs',
}

local all_config_files = vim.list_extend(vim.deepcopy(formatter_configs), vite_config_names)

local function has(dir, filename) return vim.uv.fs_stat(dir .. '/' .. filename) ~= nil end

local function find_root(from) return vim.fs.root(from, all_config_files) end

local function has_vite_plus(root)
  for _, name in ipairs(vite_config_names) do
    local path = root .. '/' .. name
    if vim.uv.fs_stat(path) then
      local f = io.open(path, 'r')
      if f then
        local content = f:read '*a'
        f:close()
        if content:find('vite%-plus', 1, false) or content:find [["vite-plus"]] or content:find [['vite-plus']] then return true end
      end
    end
  end
  return false
end

local function classify(root)
  if not root then return nil end

  for _, name in ipairs { 'biome.json', 'biome.jsonc' } do
    if has(root, name) then return { 'biome' } end
  end

  for _, name in ipairs { 'oxc.config.json', '.oxc.json' } do
    if has(root, name) then return { 'oxc' } end
  end

  if has_vite_plus(root) then return { 'vite-plus' } end

  for _, name in ipairs {
    '.prettierrc',
    '.prettierrc.json',
    '.prettierrc.yml',
    '.prettierrc.yaml',
    '.prettierrc.js',
    '.prettierrc.mjs',
    '.prettierrc.cjs',
    'prettier.config.js',
    'prettier.config.mjs',
    'prettier.config.cjs',
  } do
    if has(root, name) then return { 'prettier' } end
  end

  return nil
end

local function detect_js_formatter(bufnr)
  -- local cwd_root = find_root(vim.uv.cwd())
  -- local result = classify(cwd_root)
  -- if result then return result end

  local buf_path = vim.api.nvim_buf_get_name(bufnr)
  local buf_root = buf_path ~= '' and find_root(buf_path) or nil
  local result2 = classify(buf_root)
  if result2 then return result2 end

  return { 'biome' }
end

local function get_formatter(bufnr)
  local format = detect_js_formatter(bufnr)
  if format == 'biome' then return { 'biome-check' } end
  if format == 'vite-plus' then return { 'vp-format' } end
  if format == 'oxc' then return { 'oxc-format' } end
  if format == 'prettier' then return { 'prettierd' } end
  return { 'biome-check' }
end

return { -- Autoformat
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>f',
      function() require('conform').format { async = true, lsp_format = 'fallback' } end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  },
  ---@module 'conform'
  ---@type conform.setupOpts
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- Disable "format_on_save lsp_fallback" for languages that don't
      -- have a well standardized coding style. You can add additional
      -- languages here or re-enable it for the disabled ones.
      local disable_filetypes = { c = true, cpp = true }
      if disable_filetypes[vim.bo[bufnr].filetype] then
        return nil
      else
        return {
          timeout_ms = 500,
          lsp_format = 'fallback',
        }
      end
    end,
    formatters_by_ft = {
      lua = { 'stylua' },
      -- Conform can also run multiple formatters sequentially
      -- python = { "isort", "black" },
      --
      -- You can use 'stop_after_first' to run the first available formatter from the list
      -- javascript = { "prettierd", "prettier", stop_after_first = true },
      javascript = get_formatter,
      javascriptreact = get_formatter,

      typescript = get_formatter,
      typescriptreact = get_formatter,
    },
  },
}
