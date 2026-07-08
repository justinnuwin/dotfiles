-- Neovim-only plugins, registered with vim-plug driven from lua. plugins.vim
-- sources this from inside its plug#begin/end block (via 'lua require') so that
-- plugins.vim itself stays classic-Vim only. Each plugin is configured by a
-- sibling module that runs after plug#end() puts it on the runtimepath.
local Plug = vim.fn['plug#']

-- Insert-mode escape without a python3 dependency (replaces vim-easyescape).
Plug('max397574/better-escape.nvim')

-- Built-in LSP client + completion stack (replaces coc.nvim).
Plug('neovim/nvim-lspconfig')       -- server definitions consumed by vim.lsp.enable
Plug('hrsh7th/nvim-cmp')            -- completion engine
Plug('hrsh7th/cmp-nvim-lsp')        -- LSP completion source
Plug('hrsh7th/cmp-buffer')          -- current-buffer words source
Plug('hrsh7th/cmp-path')            -- filesystem path source
Plug('L3MON4D3/LuaSnip')            -- snippet engine (replaces coc-snippets)
Plug('saadparwaiz1/cmp_luasnip')    -- LuaSnip completion source
Plug('rafamadriz/friendly-snippets')  -- snippet collection (replaces vim-snippets)

-- Faster lua replacements for the Vim UI plugins.
Plug('nvim-lualine/lualine.nvim')           -- replaces vim-airline
Plug('lukas-reineke/indent-blankline.nvim')  -- replaces vim-indent-guides
