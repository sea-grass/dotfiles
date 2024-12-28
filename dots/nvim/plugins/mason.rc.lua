require("mason").setup()
require("mason-lspconfig").setup()

local lspconfig = require("lspconfig")

-- TODO add tsserver config for the typescript-svelte-plugin
lspconfig.tsserver.setup{}

lspconfig.svelte.setup{
  filetypes = { "svelte", "ts" }
}
