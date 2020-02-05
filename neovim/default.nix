{ pkgs }:
let
  inherit (pkgs.vimUtils.override {inherit (pkgs) vim;}) buildVimPluginFrom2Nix;
  customPlugins = pkgs.callPackage ./generated.nix {
    inherit buildVimPluginFrom2Nix;
  };

  currently_unused = ''
    " => Plugin settings {{{
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    " deoplete.nvim "{{{
    let g:deoplete#enable_at_startup = 1
    " }}}

    " 'mhinz/neovim-remote' "{{{
    if has('nvim')
      let $VISUAL = 'nvr -cc split --remote-wait'
    endif
    "}}}

    " 'mhinz/vim-signify' "{{{
    "let g:signify_sign_overwrite=0 "}}}

    " 'neoterm "{{{
    let g:neoterm_autoscroll = 1
    nnoremap <F3> :vertical :T make<CR>
    nnoremap <F4> :vertical :T make test<CR>
    " }}}

    " 'sjl/gundo.vim' "{{{
    "nnoremap <F5> :GundoToggle<CR> "}}}

    " 'junegunn/vim-easy-align' "{{{
        " Start interactive EasyAlign in visual mode
        "vmap <Enter> <Plug>(EasyAlign)
        " Start interactive EasyAlign with a Vim movement
        "nmap <Leader>a <Plug>(EasyAlign) "}}}

    " }}}
  '';

  makeVim = { extraConfig ? "", plugins ? [ ] }:
    let
      plugins' =
        builtins.filter (x: !(pkgs.lib.attrByPath [ "disabled" ] false x))
        plugins;
    in {
      enable = true;

      withNodeJs = true;
      withPython = false;
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
    {
      package = vim-asterisk;
      disabled = true;
    }
    { package = vim-polyglot; }
    { package = customPlugins.clever-f-vim; }
    { package = customPlugins.distilled-vim; }
    { package = customPlugins.flatlandia; }
    { package = customPlugins.iceberg-vim; }
    { package = customPlugins.nova-vim; }
    { package = customPlugins.nord-vim; }
    { package = customPlugins.vim-substrata; }
    { package = customPlugins.vim-clap; }
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
    { package = vim-addon-nix; }
    {
      package = LanguageClient-neovim;
      config = ''
        let g:LanguageClient_serverCommands = {
            \ 'c': ['clangd', '-background-index'],
            \ 'cpp': ['clangd', '-background-index'],
            \ 'haskell': ['hie', '--lsp'],
            \ 'javascript': ['/opt/javascript-typescript-langserver/lib/language-server-stdio.js'],
            \ 'python': ['pyls'],
            \ 'rust': ['rustup', 'run', 'nightly', 'rls'],
            \ }

        " Automatically start language servers.
        let g:LanguageClient_autoStart = 1
        let g:LanguageClient_loadSettings = 1
        let g:LanguageClient_hasSnippetSupport = 0
        " Use an absolute configuration path if you want system-wide settings
        let g:LanguageClient_settingsPath = '/home/tobim/.config/nvim/settings.json'
        set completefunc=LanguageClient#complete
        set formatexpr=LanguageClient_textDocument_rangeFormatting()

        nnoremap <silent> gh :call LanguageClient_textDocument_hover()<CR>
        nnoremap <silent> gd :call LanguageClient_textDocument_definition()<CR>
        nnoremap <silent> gr :call LanguageClient_textDocument_references()<CR>
        nnoremap <silent> gs :call LanguageClient_textDocument_documentSymbol()<CR>
        nnoremap <silent> gF :call LanguageClient_textDocument_formatting()<CR>
        vnoremap <silent> gF :call LanguageClient_textDocument_formatting()<CR>
        nnoremap <silent> <F2> :call LanguageClient_textDocument_rename()<CR>

        nnoremap <silent> zk :call LanguageClient#findLocations({'method':'$ccls/navigate','direction':'L'})<cr>
        nnoremap <silent> zl :call LanguageClient#findLocations({'method':'$ccls/navigate','direction':'D'})<cr>
        nnoremap <silent> zh :call LanguageClient#findLocations({'method':'$ccls/navigate','direction':'U'})<cr>
        nnoremap <silent> zj :call LanguageClient#findLocations({'method':'$ccls/navigate','direction':'R'})<cr>

        " bases
        nn <silent> zb :call LanguageClient#findLocations({'method':'$ccls/inheritance'})<cr>
        " bases of up to 3 levels
        nn <silent> zB :call LanguageClient#findLocations({'method':'$ccls/inheritance','levels':3})<cr>
        " derived
        nn <silent> zd :call LanguageClient#findLocations({'method':'$ccls/inheritance','derived':v:true})<cr>
        " derived of up to 3 levels
        nn <silent> zD :call LanguageClient#findLocations({'method':'$ccls/inheritance','derived':v:true,'levels':3})<cr>

        " caller
        nn <silent> zc :call LanguageClient#findLocations({'method':'$ccls/call'})<cr>
        " callee
        nn <silent> zC :call LanguageClient#findLocations({'method':'$ccls/call','callee':v:true})<cr>

        " $ccls/member
        " nested classes / types in a namespace
        nn <silent> zs :call LanguageClient#findLocations({'method':'$ccls/member','kind':2})<cr>
        " member functions / functions in a namespace
        nn <silent> zf :call LanguageClient#findLocations({'method':'$ccls/member','kind':3})<cr>
        " member variables / variables in a namespace
        nn <silent> zm :call LanguageClient#findLocations({'method':'$ccls/member'})<cr>

        augroup LanguageClient_config
          au!
          au BufEnter * let b:Plugin_LanguageClient_started = 0
          au User LanguageClientStarted setl signcolumn=yes
          au User LanguageClientStarted let b:Plugin_LanguageClient_started = 1
          au User LanguageClientStopped setl signcolumn=auto
          au User LanguageClientStopped let b:Plugin_LanguageClient_stopped = 0
          au CursorMoved * if b:Plugin_LanguageClient_started | sil call LanguageClient#textDocument_documentHighlight() | endif
        augroup END
      '';
    }
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
    { package = customPlugins.vim-pasta; }
    { package = vim-textobj-user; }
    {
      package = vim-gitgutter;
      config = ''
      '';
    }
    { package = nvim-yarp; }
    {
      package = ncm2;
      config = ''
        " enable ncm2 for all buffers
        autocmd BufEnter * call ncm2#enable_for_buffer()
        " IMPORTANT: :help Ncm2PopupOpen for more information
        set completeopt=noinsert,menuone,noselect

        autocmd BufReadPost * call ncm2#override_source('LanguageClient_cpp', {'filter': {
            \ 'name':'substitute',
            \ 'pattern': '^([a-zA-Z0-9_]+\(?).*',
            \ 'replace': '\1',
            \ 'key': 'word'}})
      '';
    }
    { package = ncm2-bufword; }
    { package = float-preview-nvim; }
    { package = customPlugins.vimagit; }
    {
      package = customPlugins.vista-vim;
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
    { package = customPlugins.git-messenger-vim; }
    { package = customPlugins.vim-textobj-variable-segment; }
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
    colorscheme substrata

    set ruler
    set cmdheight=2
    set signcolumn=yes
    set cursorline

    "hi ActiveWindow guibg=#17252c
    "hi InactiveWindow guibg=#0D1B22

    "" Call method on window enter
    "augroup WindowManagement
    "  autocmd!
    "  autocmd WinEnter * call Handle_Win_Enter()
    "augroup END

    "" Change highlight group of active/inactive windows
    "function! Handle_Win_Enter()
    "  setlocal winhighlight=Normal:ActiveWindow,NormalNC:InactiveWindow
    "endfunction

    " Set 7 lines to the cursor - when moving vertically using j/k
    set so=7

    " enable the pop-up-list for command and argument completion in
    " command mode
    set wildmenu
    set wildmode=list:longest,full

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
    set smartindent
    set shiftwidth=4
    set softtabstop=4
    set tabstop=4

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

    command! -nargs=+ Cppman silent! call system("tmux split-window cppman " . expand(<q-args>))
    autocmd FileType cpp nnoremap <silent><buffer> K <Esc>:Cppman <cword><CR>

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
