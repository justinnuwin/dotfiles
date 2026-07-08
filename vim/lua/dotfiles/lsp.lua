-- Neovim built-in LSP. Servers mirror the old coc extensions: clangd (coc-clangd),
-- pyright (coc-pyright), jsonls (coc-json). coc-pydocstring has no LSP equivalent.
-- Server definitions come from nvim-lspconfig's lsp/ files, which vim.lsp.enable()
-- picks up.

-- Advertise nvim-cmp's extra completion capabilities to every server.
vim.lsp.config('*', { capabilities = require('cmp_nvim_lsp').default_capabilities() })

vim.lsp.enable({ 'clangd', 'pyright', 'jsonls' })

-- Buffer-local LSP keymaps on attach.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('dotfiles_lsp_attach', { clear = true }),
  callback = function(args)
    local opts = { buffer = args.buf, silent = true, nowait = true }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method('textDocument/inlayHint') then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
  end,
})

-- Less distracting inlay hints.
vim.api.nvim_set_hl(0, 'LspInlayHint', { link = 'Comment' })

-- Toggle diagnostics when they get noisy.
vim.keymap.set('n', '<C-S>', function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { silent = true, desc = 'Toggle diagnostics' })
