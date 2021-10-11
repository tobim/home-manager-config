{ pkgs }:
let
  inherit (pkgs.vimUtils.override {inherit (pkgs) vim;}) buildVimPluginFrom2Nix;
  customPlugins = pkgs.callPackage ./generated.nix {
    inherit buildVimPluginFrom2Nix;
  };

  makeVim = { extraConfig ? "", plugins ? [ ] }:
    let
      plugins' =
        builtins.filter (x: !(pkgs.lib.attrByPath [ "disable" ] false x))
        plugins;
    in {
      enable = true;

      withNodeJs = false;
      withPython3 = true;

      plugins = builtins.map (builtins.getAttr "package") plugins';

      extraConfig = extraConfig + pkgs.lib.concatMapStrings (x: x.config)
        (builtins.filter (builtins.hasAttr "config") plugins');
    };

in makeVim {
  plugins = with pkgs.vimPlugins; [
    { package = editorconfig-vim;
      config = ''
        let g:EditorConfig_max_line_indicator = "none"
      '';}
    { package = vim-polyglot; }
    { package = targets-vim; }
    { package = clever-f-vim; }
    { package = customPlugins.distilled-vim; }
    { package = customPlugins.flatlandia; }
    { package = iceberg-vim; }
    { package = customPlugins.nova-vim; }
    { package = nord-nvim; }
    { package = customPlugins.vim-substrata; }
    { package = vim-clap; }
    { package = customPlugins.vim-visual-star-search; }
    { package = fzfWrapper; }
    {
      package = fzf-vim;
      config = ''
        command! -bang -nargs=* GGrep
          \ call fzf#vim#grep('git grep --recurse-submodules --line-number '.shellescape(<q-args>), 0, <bang>0)

        nnoremap [fzf] <Nop>
        nmap <space> [fzf]
        nnoremap <silent> [fzf]f :Files<CR>
        nnoremap <silent> [fzf]a :Buffers<CR>
        nnoremap <silent> [fzf]m :History<CR>
        nnoremap <silent> [fzf]g :GGrep<CR>
        nnoremap <silent> [fzf]h :Helptags<CR>

        au FileType fzf set nonu nornu signcolumn=no
        let g:fzf_layout = { 'window': 'call FloatingFZF()' }

        function! FloatingFZF()
          let buf = nvim_create_buf(v:false, v:true)
          call setbufvar(buf, '&signcolumn', 'no')

          let height = min([&lines - 3, 30])
          let width = float2nr(&columns - (&columns * 2 / 10))
          let col = float2nr((&columns - width) / 2)
          let row = &lines - height - 5

          let opts = {
                \ 'relative': 'editor',
                \ 'row': row,
                \ 'col': col,
                \ 'width': width,
                \ 'height': height
                \ }

          call nvim_open_win(buf, v:true, opts)
        endfunction
      '';
    }
    {
      #disable = true;
      package = nvim-treesitter;
      config = ''
        lua <<EOF
        vim.cmd('packadd nvim-treesitter')
        require'nvim-treesitter.configs'.setup {
          --ensure_installed = "all",     -- one of "all", "language", or a list of languages
          highlight = {
            enable = true,              -- false will disable the whole extension
            disable = { "c" },          -- list of language that will be disabled
          },
        }
        EOF
      '';
    }
    {
      package = nvim-lspconfig;
      config = ''
        lua <<EOF
        vim.cmd('packadd nvim-lspconfig')
        local lspconfig = require('lspconfig')
        local util = require 'lspconfig/util'

        vim.cmd('packadd lsp-status-nvim')
        local lsp_status = require('lsp-status')

        lsp_status.register_progress()
        lsp_status.config({
          status_symbol = ''',
          indicator_errors = 'e',
          indicator_warnings = 'w',
          indicator_info = 'i',
          indicator_hint = 'h',
          indicator_ok = '✔️',
          spinner_frames = { '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷' },
        })

        --lspconfig.ccls.setup{
        --  on_attach = on_attach,
        --  capabilities = lsp_status.capabilities
        --}
        --lspconfig.pyls_ms.setup{
        --  capabilities = lsp_status.capabilities
        --}
        lspconfig.pyright.setup{
          capabilities = lsp_status.capabilities
        }
        lspconfig.pylsp.setup{
          capabilities = lsp_status.capabilities
        }
        lspconfig.clangd.setup{
          capabilities = lsp_status.capabilities
        }
        lspconfig.hls.setup{
          capabilities = lsp_status.capabilities
        }
        lspconfig.rnix.setup{
          capabilities = lsp_status.capabilities
        }
        lspconfig.rust_analyzer.setup{
          capabilities = lsp_status.capabilities,
          root_dir = util.root_pattern("Cargo.toml", "rust-project.json")
        }

        local on_attach = function(client, bufnr)
          lsp_status.on_attach(client, bufnr)
          --completion.on_attach(client, bufnr)
          local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
          local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

          buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

          local opts = { noremap=true, silent=true }
          buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
          buf_set_keymap('n', '<c-]>', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
          buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
          buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
          buf_set_keymap('n', '1gD', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
          buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
          buf_set_keymap('n', 'g0', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
          buf_set_keymap('n', 'gW', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', opts)
          buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
          buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
          buf_set_keymap('n', 'gl', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)

          -- Set some keybinds conditional on server capabilities
          if client.resolved_capabilities.document_formatting then
            buf_set_keymap('n', 'gq', "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
          end
          if client.resolved_capabilities.document_range_formatting then
            buf_set_keymap('v', 'gq', "<cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
          end
        end

        -- Use a loop to conveniently both setup defined servers 
        -- and map buffer local keybindings when the language server attaches
        --local servers = { "clangd", "rust_analyzer", "rnix", "hls" }
        local servers = { "clangd", "rnix", "hls" }
        for _, lsp in ipairs(servers) do
          lspconfig[lsp].setup { on_attach = on_attach }
        end

        EOF
      '';
    }
    {
      package = lsp-status-nvim;
      config = ''
        function! LspStatus() abort
          if luaeval('#vim.lsp.buf_get_clients() > 0')
            return luaeval("require('lsp-status').status()")
          endif
          return '''
        endfunction

        set statusline=%f\ %h%w%m%r%=%{LspStatus()}\ %-14.(%l,%c%V%)\ %P
      '';
    }
    {
      package = completion-nvim;
      config = ''
        " Use completion-nvim in every buffer
        autocmd BufEnter * lua require'completion'.on_attach()

        " Set completeopt to have a better completion experience
        set completeopt=menuone,noinsert,noselect

        " Avoid showing message extra message when using completion
        set shortmess+=c
      '';
    }
    { package = vim-addon-nix; }
    {
      package = customPlugins.vim-altr;
      config = ''
        nmap <silent> gj <Plug>(altr-forward)
        nmap <silent> gk <Plug>(altr-back)
      '';
    }
    {
      package = vim-localvimrc;
      config = ''
        let g:localvimrc_sandbox = 0
        let g:localvimrc_persistent = 2
        let g:localvimrc_persistence_file = expand(dataDir . '/localvimrc_persistent')
      '';
    }
    { package = vim-pasta; }
    { package = vim-textobj-user; }
    {
      package = vim-gitgutter;
      config = ''
      '';
    }
    { package = nvim-yarp; }
    { package = vimagit; }
    {
      package = vista-vim;
      config = ''
        " How each level is indented and what to prepend.
        " This could make the display more compact or more spacious.
        " e.g., more compact: ["▸ ", ""]
        let g:vista_icon_indent = ["╰─▸ ", "├─▸ "]

        " Executive used when opening vista sidebar without specifying it.
        " See all the avaliable executives via `:echo g:vista#executives`.
        let g:vista_default_executive = 'lcn'

        " To enable fzf's preview window set g:vista_fzf_preview.
        " The elements of g:vista_fzf_preview will be passed as arguments to
        " fzf#vim#with_preview()
        " For example:
        let g:vista_fzf_preview = ['right:50%']

        " Ensure you have installed some decent font to show these pretty
        " symbols, then you can enable icon for the kind.
        let g:vista#renderer#enable_icon = 1

        autocmd BufEnter * call UpdateSideBarWidth()
        autocmd VimResized * call UpdateSideBarWidth()
        function! UpdateSideBarWidth()
          let width = min([&columns - 80 - 3, 50])
          let g:vista_sidebar_width = width
        endfunction
      '';
    }
    { package = git-messenger-vim; }
    { package = vim-textobj-variable-segment; }
    { package = undotree; }
  ];

  extraConfig = ''
    "" => General {{{
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "" reload an open file if it is changed from outside
    set autoread

    "" don't update the display while executing macros
    set lazyredraw

    "" search from current directory upwards for ctags file
    set tags+=tags;/

    set noswapfile

    set shell=${pkgs.bash}/bin/bash

    au BufEnter * let g:bufcwd = getcwd()

    "set background=dark
    set termguicolors
    colorscheme nord

    set ruler
    set cmdheight=2
    set signcolumn=yes
    set cursorline

    "hi ActiveWindow guibg=#17252c
    "hi InactiveWindow guibg=#0D1B22

    " Set 7 lines to the cursor - when moving vertically using j/k
    set so=7

    " enable the pop-up-list for command and argument completion in
    " command mode
    "set wildmenu
    "set wildmode=list:longest,full

    " do not ask for confirmation after displaying messages
    set shortmess+=filmnrxoOtT

    set formatoptions+=r
    set formatoptions-=o
    " set formatoptions-=t

    " let backspace traverse line breaks and delete indentations
    " in indentation step size (tabstop)
    set backspace=indent,eol,start

    " enable case sensitive searches when the search term contains
    " upper case characters, otherwise not
    set ignorecase
    set smartcase

    "" enable auto indentation and set tab width
    "set smartindent
    "set shiftwidth=4
    "set softtabstop=4
    "set tabstop=4

    " always convert tabs to spaces
    set expandtab

    " always draw a status line
    set laststatus=2

    " Writes to the unnamed register also writes to the * and + registers. This
    " makes it easy to interact with the system clipboard
    if has ('unnamedplus')
      set clipboard=unnamedplus
    else
      set clipboard=unnamed
    endif

    " do not beep or flash
    " important: t_vb= must be set in gvimrc as well!
    set noerrorbells
    set visualbell
    set t_vb=
    set inccommand=split
    set list listchars=tab:¦\ ,trail:˽

    set splitbelow
    set splitright

    " => Keymappings
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    let mapleader = ","
    let g:mapleader = ","
    let maplocalleader = ";"

    " Y yanks from cursor to $
    map Y y$

    " Window navigation with control + {h,j,k,l}
    noremap <C-J> <C-W>j
    noremap <C-K> <C-W>k
    noremap <C-H> <C-W>h
    noremap <C-L> <C-W>l

    " lookup vim help for the word under cursor
    noremap <leader>h : help <C-R>=expand("<cword>")<CR><CR><C-W>p

    " overwrite selection and preserve the default register
    vnoremap <leader>p "_dP

    " fast saving
    nnoremap <leader>w :w!<cr>

    " press j+k to escape from insert mode
    inoremap jk <ESC>
    inoremap kj <ESC>

    " close terminal with esc...
    tnoremap <ESC> <C-\><C-n>
    tnoremap jk <C-\><C-n>
    tnoremap jk <C-\><C-n>

    " append current line to the next
    nnoremap <leader>J :m+1<CR>kJ

    " => Command-line Mode keymappings
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    " Readline emulation
    cnoremap <c-a> <home>
    cnoremap <c-e> <end>

    " Ctrl-[hl]: Move left/right by word
    cnoremap <c-h> <s-left>
    cnoremap <c-l> <s-right>

    " Ctrl-Space: Show history
    cnoremap <c-@> <c-f>

    cnoremap <c-j> <down>
    cnoremap <c-k> <up>
    cnoremap <c-f> <left>
    cnoremap <c-g> <right>

    " Ctrl-Delete: Delete previous word.
    cnoremap <c-d> <c-w>

    " Ctrl-v: Paste
    cnoremap <c-v> <c-r>"

    " press j+k to escape from insert mode
    cnoremap jk <C-c>
    cnoremap kj <C-c>

    " Put plugins and dictionaries in this dir
    let dataDir = $HOME.'/.local/share/nvim'
    call mkdir(dataDir, 'p')

    " Save central undo files
    if has('persistent_undo')
        let dir_ = expand(dataDir . '/undo')
        call mkdir(dir_, 'p')
        let &undodir = dir_
        set undofile
    endif
    if has('write_backup')
        let dir_ = expand(dataDir . '/backup')
        call mkdir(dir_, 'p')
        let &backupdir = dir_
        set backup
    endif

  '';

}
