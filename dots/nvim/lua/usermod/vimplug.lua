-- Lua Plug adapter for vim-plug
--
-- Usage:
-- ```
-- Plug.begin()
--
-- Plug 'vimwiki/vimwiki'
--
-- Plug.ends()
-- ```
--
-- Inspired by:
-- @see https://dev.to/vonheikemen/neovim-using-vim-plug-in-lua-3oom

local configs = {
  lazy = {},
  start = {},
}

local Plug = {
  begin = vim.fn['plug#begin'],
  ends = function()
    vim.fn['plug#end']()
    for _, config in pairs(configs.start) do
      config()
    end
  end
}

local plugName = function(repo)
  return repo:match("^[%w-]+/([%w-_.]+)$")
end

local applyConfig = function(plugin_name)
  local fn = configs.lazy[plugin_name]
  if type(fn) == 'function' then
    fn()
  end
end

return setmetatable(Plug, {
  __call = function(_, repo, opts)
    opts = opts or vim.empty_dict()

    -- some aliases for `do` and `for`
    opts['do'] = opts['do'] or opts.run
    opts.run = nil

    opts['for'] = opts['for'] or opts.ft
    opts.ft = nil

    vim.call('plug#', repo, opts)

    if type(opts.config) == 'function' then
      local plugin = opts.as or plugName(repo)

      if opts['for'] == nil and opts.on == nil then
        configs.start[plugin] = opts.config
      else
        configs.lazy[plugin] = opts.config
        vim.api.nvim_create_autocmd('User', {
          pattern = plugin,
          once = true,
          callback = function()
            applyConfig(plugin)
          end,
        })
      end
    end
  end
})
