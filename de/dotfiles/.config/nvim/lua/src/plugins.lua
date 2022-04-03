local fn = vim.fn

local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system {
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  }
  print "Installing packer close and reopen Neovim..."
  vim.cmd [[packadd packer.nvim]]
end

vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]]


local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

return packer.startup(function(use)

  -- Basic / required
  use "wbthomason/packer.nvim" 
  use "nvim-lua/popup.nvim" 
  use "nvim-lua/plenary.nvim" 

  -- Completion
  use "hrsh7th/nvim-cmp"
  use "hrsh7th/cmp-path" 
  use "hrsh7th/cmp-buffer" 
  use "hrsh7th/cmp-nvm-lsp" 
  use "saadparwaiz1/cmp_luasnip" 

  -- Snippets
  use "L3MON4D3/LuaSnip"

  -- LSP
  use "neovim/nvim-lspconfig"
  use "williamboman/nvim-lsp-installer"

  -- Functionality
  use "junegunn/fzf.vim"


  
  if PACKER_BOOTSTRAP then
    require("packer").sync()
  end
end)
