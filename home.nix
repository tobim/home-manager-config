{ pkgs, ... }:

let
    gst_packages = with pkgs; [
      gstreamer
      gst-plugins-good
      gst-plugins-bad
      gst-plugins-ugly
      gst-ffmpeg
    ];

    linux_packages = with pkgs; [
      pkgs.aqbanking
      pkgs.chromium
      pkgs.cutegram
      pkgs.dtrx
      pkgs.firefox
      pkgs.gparted
      pkgs.kbfs
      pkgs.meld
      pkgs.okular
      pkgs.qutebrowser
      pkgs.pdfshuffler
      pkgs.xournal
      pkgs.xsel
      haskellPackages.buchhaltung
    ] ++ gst_packages;

    darwin_packages = with pkgs.darwin.apple_sdk; [
      frameworks.Security
      frameworks.CoreFoundation
      frameworks.CoreServices
    ];

    home_packages = with pkgs; [
      pkgs.beets
      pkgs.hledger
      pkgs.ncmpcpp
      pkgs.signal-desktop
      pkgs.youtube-dl
    ];

    default_packages = [
      pkgs.cmake
      pkgs.clang-tools
      pkgs.cloc
      pkgs.coreutils
      pkgs.fzf
      pkgs.git
      pkgs.gnumake
      pkgs.gnupg
      pkgs.htop
      pkgs.imagemagick
      pkgs.isync
      pkgs.keybase
      pkgs.ncdu
      pkgs.ninja
      pkgs.notmuch
      pkgs.pass
      pkgs.ripgrep
      pkgs.syncthing
      pkgs.tectonic
      pkgs.tmux
      pkgs.tree
      pkgs.zsh
    ];

    cpp_packages = [] ++
      (if (builtins.hasAttr "cquery" pkgs.cpppkgs) then [ pkgs.cpppkgs.cquery ] else [])
    ;

    python_packages = [
      (pkgs.python3.withPackages (ps: with ps; [
        flake8
        pylint
        yapf
      ] ++
      (if (builtins.hasAttr "python-language-server" ps) then with ps;[
        python-language-server
        pyls-mypy
        pyls-isort
        rope
      ] else [])))
    ];

    customPlugins = {
      vim-clang-format = pkgs.vimUtils.buildVimPlugin {
        name = "vim-clang-format";
        src = pkgs.fetchFromGitHub {
          owner = "rhysd";
          repo = "vim-clang-format";
          rev = "8ff1660a1e9f856479fffe693743521f4f3068cb";
          sha256 = "1g9vs6cg7irmwqa1lz6i7xbq50svykhvax12vx7cpf2bxs8jfp3n";
        };
      };

      vim-diminactive = pkgs.vimUtils.buildVimPlugin {
        name = "vim-diminactive";
        src = pkgs.fetchFromGitHub {
          owner = "blueyed";
          repo = "vim-diminactive";
          rev = "6f2e14e6ff6a038285937c378ec3685e6ff7ee36";
          sha256 = "14jf5hh3v2f5wb10v09ygx15pxbwziv20pwv0fqkakxwf0vqwd50";
        };
        buildPhase = "true";
      };

      vim-pasta = pkgs.vimUtils.buildVimPlugin {
        name = "vim-pasta";
        src = pkgs.fetchFromGitHub {
          owner = "sickill";
          repo = "vim-pasta";
          rev = "f77cc5d68ce70a53cd02798a98da997376d62188";
          sha256 = "1qip74zqknsajgrp8lcrpwgs1jiiy06d5pf5r123zq7g5di196dq";
        };
      };

      vim-textobj-user = pkgs.vimUtils.buildVimPlugin {
        name = "vim-textobj-user";
        src = pkgs.fetchFromGitHub {
          owner = "kana";
          repo = "vim-textobj-user";
          rev = "e231b65797b5765b3ee862d71077e9bd56f3ca3e";
          sha256 = "0zsgr2cn8s42d7jllnxw2cvqkl27lc921d1mkph7ny7jgnghaay9";
        };
      };

      vim-visual-star-search = pkgs.vimUtils.buildVimPlugin {
        name = "vim-visual-star-search";
        src = pkgs.fetchFromGitHub {
          owner = "bronson";
          repo = "vim-visual-star-search";
          rev = "fa55818903301d61cef67341d3524a63a14bc033";
          sha256 = "1ny6sdl08mbh5j3fvsznlgxdv2hip190dmsgs22gygn8wpj2xc8l";
        };
      };

      vim-textobj-variable-segment = pkgs.vimUtils.buildVimPlugin {
        name = "vim-textobj-variable-segment";
        src = pkgs.fetchFromGitHub {
          owner = "Julian";
          repo = "vim-textobj-variable-segment";
          rev = "6c60e9b831961f9ed6bc4ff229792745747de3e8";
          sha256 = "0q9n781nv3pk1hvc02034gpyd395n7qzhk8cka2ydd5z31zg2dgf";
        };
      };

      flatlandia = pkgs.vimUtils.buildVimPlugin {
        name = "flatlandia";
        src = pkgs.fetchFromGitHub {
          owner = "jordwalke";
          repo = "flatlandia";
          rev = "05069c3777c463b25b609dca8dccacf9f75e2ce3";
          sha256 = "04mk80zaxjxh9hdy9ll12ri9pq6s0p0lz1myg7yfz8rgyd74kaqz";
        };
      };
    };

in
{
  home = {
    packages = default_packages ++ cpp_packages ++ python_packages ++
      (if builtins.currentSystem == "x86_64-linux"
      then linux_packages ++ home_packages
      else if builtins.currentSystem == "x86_64-darwin"
      then darwin_packages
      else []);

    sessionVariables = {
      EDITOR = "nvim";
      GS_OPTIONS = "-sPAPERSIZE=a4";
    };
  };

  pam.sessionVariables = {
    EDITOR = "nvim";
  };

  #services.gpg-agent = {
  #  enable = true;
  #  defaultCacheTtl = 1800;
  #  enableSshSupport = true;
  #};

  programs.zsh = {
    enable = true;
  };

  programs.git = {
    enable = true;
    userName = "Tobias Mayer";
    userEmail = "tobim@fastmail.fm";
    aliases = {
      st = "status --short --branch ";
      ci = "commit ";
      amend = "commit --amend ";
      undo = "reset --soft HEAD^ ";
      glog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' ";
      grog = "log --graph --abbrev-commit --decorate --all --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(dim white) - %an%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n %C(white)%s%C(reset)' ";
    };
    extraConfig=''
      [transfer]
        fschkobjects = true
      '';
  };

  programs.neovim = {
    enable = true;

    configure = {
      vam.knownPlugins = pkgs.vimPlugins // customPlugins;
      vam.pluginDictionaries = [
        { names = [
          "ale"
          "deoplete-nvim"
          "fugitive"
          "fzfWrapper"
          "fzf-vim"
          "idris-vim"
          "LanguageClient-neovim"
          "purescript-vim"
          "rhubarb"
          "vim-addon-nix"
          "vim-airline"
          "vim-clang-format"
          "vim-diminactive"
          "vim-easy-align"
          "vim-gitgutter"
          "vim-operator-user"
          "vim-pasta"
          "vim-textobj-user"
          "vim-textobj-variable-segment"
          "vim-visual-star-search"
          "flatlandia"
          "gruvbox"
        ]; }
      ];

      customRC = ''
        "" => General {{{
        """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        "" sets how many lines of history VIM has to remember
        "set history=1000

        "" reload an open file if it is changed from outside
        set autoread

        "" don't update the display while executing macros
        set lazyredraw

        "" vim sets terminal title
        "set title


        "set helplang=en

        "" remove trailing whitespaces on save
        "" autocmd BufRead,BufWritePre * if ! &bin | silent! %s/\s\+$// | endif

        "" search from current directory upwards for ctags file
        set tags+=tags;/

        "" ignore the following file endings completely
        set wildignore=*.swp,*.o,*.oo,*.pyc,*.info,*.aux,*.dvi,*.bbl,*.blg
        set wildignore+=*.brf,*.cb,*.ind,*.idx,*.ilg,*.inx,*.out,*.toc
        set wildignore+=*/tmp/*,*.so,*.a,*.la,*.zip,*.bz2,*.gz,*.tar

        "" give the following file endings less priority
        "set suffixes=.bak,~,.log,.h,.P

        " Put plugins and dictionaries in this dir (also on Windows)
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

        set exrc

        set noswapfile

        au BufEnter * let g:bufcwd = getcwd()
        "}}}

        " => VIM user interface {{{
        """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        " enable syntax highlighting
        syntax enable

        " set colors and font according to preferences
        "colorscheme desert_mod
        "colorscheme desert
        "set termguicolors
        set background=dark
        "let g:gruvbox_italic=1
        colorscheme gruvbox
        " set guifont=Anonymous\ Pro\ 11
        " set guifont=Anonymous\ Pro\ for\ Powerline\ 11
        "set guifont=DejaVu\ Sans\ Mono\ 11

        " Set 7 lines to the cursor - when moving vertically using j/k
        set so=7

        " allow mouse interaction
        "set mouse=a

        " enable the pop-up-list for command and argument completion in
        " command mode
        set wildmenu
        set wildmode=list:longest,full

        " show the current cursor position (line,column and file %)
        set ruler

        " do not ask for confirmation after displaying messages
        set shortmess+=filmnrxoOtT

        " make the command bar 2 lines high
        set cmdheight=2

        " Always draw the signcolumn
        set signcolumn=yes

        " highlight current line
        set cursorline

        " let backspace traverse line breaks and delete indentations
        " in indentation step size (tabstop)
        set backspace=indent,eol,start

        " enable case sensitive searches when the search term contains
        " upper case characters, otherwise not
        set ignorecase
        set smartcase

        " highlight search results
        set hlsearch
        " search as you type
        set incsearch

        "if executable('ag')
        "  set grepprg=ag\ --nogroup\ --column\ --smart-case\ --nocolor\ --follow\ --ignore\ tags
        "  set grepformat=%f:%l:%c:%m
        "elseif executable('ack')
        "  set grepprg=ack\ --nogroup\ --column\ --smart-case\ --nocolor\ --follow\ $*
        "  set grepformat=%f:%l:%c:%m
        "elseif executable('ack-grep')
        "  set grepprg=ack\ --nogroup\ --column\ --smart-case\ --nocolor\ --follow\ $*
        "  set grepformat=%f:%l:%c:%m
        "endif

        "" enable auto indentation and set tab width
        set smartindent
        set shiftwidth=4
        set softtabstop=4
        set tabstop=4

        " always convert tabs to spaces
        set expandtab

        " wrap lines to indentation
        "set breakindent
        "set breakindentopt=shift:-1

        " set \m to default for regexes
        " set magic " this is the default

        " always draw a status line
        set laststatus=2

        " the mode is indicated by powerline if available
        "set noshowmode

        " enable extended % matching
        "runtime macros/matchit.vim

        " highlight matching ()[]{}...
        "set showmatch

        " time to wait until swap file is written / cursorhold autocomd is fired
        "set updatetime=300

        " the timeout for key combinations and mappings
        "set timeoutlen=300

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

        "if has ('ballooneval')
        "  set balloondelay=100
        "endif
        "set noequalalways

        if exists('&inccommand')
          set inccommand=split
        endif

        set list listchars=tab:¦\ ,trail:˽
        ""set listchars=tab:▶\ ,eol:★
        ""set listchars+=trail:◥
        "set listchars+=extends:❯ "〉
        "set listchars+=precedes:❮
        "  "if has('conceal')
          "  set conceallevel=1
          "  set listchars+=conceal:Δ
          "endif
        " Mark lines that have been wrapped
        "set showbreak=↪

        "if has('gui_running')
        "" open maximized
        "    "set lines=999 columns=9999
        "    "if s:is_windows
        "    "  autocmd GUIEnter * simalt ~x
        "    "endif

        "    set guioptions+=t "tear off menu items
        "    set guioptions-=T "toolbar icons

        "    "if s:is_macvim
        "    "  set gfn=Ubuntu_Mono:h14
        "    "  set transparency=2
        "    "endif

        "    "if s:is_windows
        "    "  set gfn=Ubuntu_Mono:h10
        "    "endif

        "    "if has('gui_gtk')
        "    "  set gfn=Ubuntu\ Mono\ 11
        "    "endif
        "else
        "  if $COLORTERM == 'gnome-terminal'
        "    set t_Co=256 "why you no tell me correct colors?!?!
        "  endif
        "  if $TERM_PROGRAM == 'iTerm.app'
        "" different cursors for insert vs normal mode
        "    if exists('$TMUX')
        "      let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
        "      let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
        "    else
        "      let &t_SI = "\<Esc>]50;CursorShape=1\x7"
        "      let &t_EI = "\<Esc>]50;CursorShape=0\x7"
        "    endif
        "  endif
        "endif
        ""}}}

        " => Keymappings {{{
        """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        let mapleader = ","
        let g:mapleader = ","
        let maplocalleader = ";"

        " Y yanks from cursor to $
        map Y y$

        " If you like control + vim direction key to navigate
        " windows then perform the remapping
        "
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
        " }}}

        " => Command-line Mode keymappings {{{
        """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

        " Bash like keys for the command line. These resemble personal zsh mappings
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

        " Ctrl-Delete: Delete previous word. HACK ALERT! Ctrl-Delete sends d in iTerm2
        cnoremap <c-d> <c-w>

        " Ctrl-v: Paste
        cnoremap <c-v> <c-r>"

        " press j+k to escape from insert mode
        cnoremap jk <C-c>
        cnoremap kj <C-c>
        " }}}

        " => Plugin settings {{{
        """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

        " deoplete.nvim "{{{
        let g:deoplete#enable_at_startup = 1
        " }}}

        " fzf.vim "{{{
        command! -bang -nargs=* GGrep
          \ call fzf#vim#grep('git grep --line-number '.shellescape(<q-args>), 0, <bang>0)

        nnoremap [fzf] <Nop>
        nmap <space> [fzf]
        nnoremap <silent> [fzf]f :Files<CR>
        nnoremap <silent> [fzf]a :Buffers<CR>
        nnoremap <silent> [fzf]m :History<CR>
        nnoremap <silent> [fzf]g :GGrep<CR>
        nnoremap <silent> [fzf]h :Helptags<CR>
        " }}}

        " denite.nvim "{{{

        " " Change mappings
        " "call denite#custom#map('insert', 'jk', 'leave-mode')
        " "call denite#custom#map('insert', 'kj', 'leave-mode')
        "
        " " Map space to the prefix for Denite
        " nnoremap [denite] <Nop>
        " nmap <space> [denite]
        "
        " " use git file list if in git directory
        " call denite#custom#alias('source', 'file_rec/git', 'file_rec')
        " call denite#custom#var('file_rec/git', 'command', ['git', 'ls-files', '-co', '--exclude-standard'])
        " nnoremap <silent> [denite]f :<C-u>Denite `finddir('.git', ';') != ''' ? 'file_rec/git' : 'file_rec'`<CR>
        "
        " " Quick MRU search
        " nnoremap <silent> [denite]m :<C-u>Denite -buffer-name=mru file_mru<CR>
        "
        " " Quick buffer change
        " nnoremap <silent> [denite]s :<C-u>Denite buffer<CR>
        "
        " " Quick registers
        " nnoremap <silent> [denite]r :<C-u>Denite -buffer-name=register register<CR>
        "
        " " Quick buffer and mru
        " "nnoremap <silent> [denite]u :<C-u>Denite -buffer-name=buffers buffer file_mru<CR>
        "
        " " Quick yank history
        " nnoremap <silent> [denite]y :<C-u>Denite -buffer-name=yanks history/yank<CR>
        "
        " " Quick outline
        " "nnoremap <silent> [denite]o :<C-u>Denite -vertical -buffer-name=outline outline<cr>
        "
        " " Quick sessions (projects)
        " nnoremap <silent> [denite]p :<C-u>Denite -buffer-name=sessions session<CR>
        "
        " " Quick sources
        " "nnoremap <silent> [denite]a :<C-u>Denite -buffer-name=sources source<CR>

        " }}}

        " vim-airline "{{{
        "let g:airline_powerline_fonts = 1
        "let g:airline#extensions#ale#enabled = 1
        " }}}

        " 'mhinz/vim-signify' "{{{
        "let g:signify_sign_overwrite=0 "}}}

        " 'sjl/gundo.vim' "{{{
        "nnoremap <F5> :GundoToggle<CR> "}}}

        " 'junegunn/vim-easy-align' "{{{
            " Start interactive EasyAlign in visual mode
            "vmap <Enter> <Plug>(EasyAlign)
            " Start interactive EasyAlign with a Vim movement
            "nmap <Leader>a <Plug>(EasyAlign) "}}}

        " 'rhysd/vim-clang-format' "{{{
        let g:clang_format#detect_style_file = 1
        " map to <Leader>cf in C++ code
        autocmd FileType c,cpp,objc nnoremap <buffer><Leader>cf :<C-u>ClangFormat<CR>
        autocmd FileType c,cpp,objc vnoremap <buffer><Leader>cf :ClangFormat<CR>
        " if you install vim-operator-user
        autocmd FileType c,cpp,objc map <buffer><Leader>x <Plug>(operator-clang-format)
        "}}}

        " 'jpalardy/vim-slime' "{{{
        "let g:slime_target = "tmux"
        " }}}

        " 'shumphrey/fugitive-gitlab.vim' "{{{
        "let g:fugitive_gitlab_domains = ['http://jkmchnx.fe.hhi.de:8001']
        " }}}

        " w0rp/ale "{{{
        "let g:ale_linters = {'cpp': ['clang']}
        let g:ale_python_pylint_options = '--rcfile setup.cfg'
        nnoremap <silent> <C-p> <Plug>(ale_previous_wrap)
        nnoremap <silent> <C-n> <Plug>(ale_next_wrap)
        " }}}

        " {{{
        " Required for operations modifying multiple buffers like rename.
        set hidden

        let g:LanguageClient_serverCommands = {
            \ 'c': ['cquery', '--log-file=/tmp/cq.log'],
            \ 'cpp': ['cquery', '--log-file=/tmp/cq.log'],
            \ 'haskell': ['hie', '--lsp'],
            \ 'javascript': ['/opt/javascript-typescript-langserver/lib/language-server-stdio.js'],
            \ 'python': ['pyls'],
            \ 'rust': ['rustup', 'run', 'nightly', 'rls'],
            \ }

        " Automatically start language servers.
        let g:LanguageClient_autoStart = 1
        let g:LanguageClient_loadSettings = 1
        " Use an absolute configuration path if you want system-wide settings
        let g:LanguageClient_settingsPath = '/home/tobim/.config/nvim/settings.json'
        set completefunc=LanguageClient#complete
        set formatexpr=LanguageClient_textDocument_rangeFormatting()

        nnoremap <silent> gh :call LanguageClient_textDocument_hover()<CR>
        nnoremap <silent> gd :call LanguageClient_textDocument_definition()<CR>
        nnoremap <silent> gr :call LanguageClient_textDocument_references()<CR>
        nnoremap <silent> gs :call LanguageClient_textDocument_documentSymbol()<CR>
        nnoremap <silent> gf :call LanguageClient_textDocument_formatting()<CR>
        vnoremap <silent> gf :call LanguageClient_textDocument_formatting()<CR>
        nnoremap <silent> <F2> :call LanguageClient_textDocument_rename()<CR>
        " }}}

        " 'w0rp/ale' "{{{
        " }}}

        " 'arakashic/chromatica.nvim' "{{{
        "let g:chromatica#enable_at_startup=1
        " }}}

        " 'parsonsmatt/intero-neovim' "{{{
        " Process management:
        "nnoremap <Leader>hio :InteroOpen<CR>
        "nnoremap <Leader>hik :InteroKill<CR>
        "nnoremap <Leader>hic :InteroHide<CR>
        "nnoremap <Leader>hil :InteroLoadCurrentModule<CR>
        "
        "" REPL commands
        "nnoremap <Leader>hie :InteroEval<CR>
        "nnoremap <Leader>hit :InteroGenericType<CR>
        "nnoremap <Leader>hiT :InteroType<CR>
        "nnoremap <Leader>hii :InteroInfo<CR>
        "nnoremap <Leader>hiI :InteroTypeInsert<CR>
        "
        "" Go to definition:
        "nnoremap <Leader>hid :InteroGoToDef<CR>
        "
        "" Highlight uses of identifier:
        "nnoremap <Leader>hiu :InteroUses<CR>
        "
        "" Reload the file in Intero after saving
        "autocmd! BufWritePost *.hs InteroReload
        "autocmd! BufWritePost package.yaml silent !hpack --silent
        " }}}

        " 'eagletmt/neco-ghc') "{{{
        " Disable haskell-vim omnifunc
        let g:haskellmode_completion_ghc = 0
        autocmd FileType haskell setlocal omnifunc=necoghc#omnifunc
        " }}}

        " }}}
      '';
    };

  };

  programs.gnome-terminal = if builtins.currentSystem == "x86_64-linux" then {
    enable = true;
    showMenubar = false;
    profile = {
      "5ddfe964-7ee6-4131-b449-26bdd97518f7" = {
        default = true;
        visibleName = "Tomorrow Night";
        cursorShape = "ibeam";
        font = "DejaVu Sans Mono 8";
        showScrollbar = false;
        colors = {
          foregroundColor = "rgb(197,200,198)";
          palette = [
            "rgb(0,0,0)" "rgb(145,34,38)"
            "rgb(119,137,0)" "rgb(174,123,0)"
            "rgb(103,123,192)" "rgb(104,42,155)"
            "rgb(43,102,81)" "rgb(146,149,147)"
            "rgb(102,102,102)" "rgb(204,102,102)"
            "rgb(181,189,104)" "rgb(240,198,116)"
            "rgb(140,152,191)" "rgb(178,148,187)"
            "rgb(138,190,183)" "rgb(236,235,236)"
          ];
          boldColor = "rgb(138,186,183)";
          backgroundColor = "rgb(29,31,33)";
        };
      };
    };
  } else {};

  xdg.configFile."kitty/kitty.conf".text = ''
  include $HOME/misc/base16-kitty/base16-gruvbox-dark-medium-256.conf

  # Base16 Gruvbox dark, medium - kitty color config
  # Dawid Kurek (dawikur@gmail.com), morhetz (https://github.com/morhetz/gruvbox)
  background #282828
  foreground #d5c4a1
  selection_background #d5c4a1
  selection_foreground #282828
  url_color #bdae93
  cursor #d5c4a1

  # normal
  color0 #282828
  color1 #fb4934
  color2 #b8bb26
  color3 #fabd2f
  color4 #83a598
  color5 #d3869b
  color6 #8ec07c
  color7 #d5c4a1

  # bright
  color8 #665c54
  color9 #fb4934
  color10 #b8bb26
  color11 #fabd2f
  color12 #83a598
  color13 #d3869b
  color14 #8ec07c
  color15 #d5c4a1

  # extended base16 colors
  color16 #fe8019
  color17 #d65d0e
  color18 #3c3836
  color19 #504945
  color20 #bdae93
  color21 #ebdbb2
  '';

  xdg.configFile."fish/functions/fish_prompt.fish".text = ''
  function fish_prompt
    set -l last_status $status

    if not set -q __fish_git_prompt_show_informative_status
      set -g __fish_git_prompt_show_informative_status 1
    end
    if not set -q __fish_git_prompt_color_branch
      set -g __fish_git_prompt_color_branch brmagenta
    end
    if not set -q __fish_git_prompt_showupstream
      set -g __fish_git_prompt_showupstream "informative"
    end
    if not set -q __fish_git_prompt_showdirtystate
      set -g __fish_git_prompt_showdirtystate "yes"
    end
    if not set -q __fish_git_prompt_color_stagedstate
      set -g __fish_git_prompt_color_stagedstate yellow
    end
    if not set -q __fish_git_prompt_color_invalidstate
      set -g __fish_git_prompt_color_invalidstate red
    end
    if not set -q __fish_git_prompt_color_cleanstate
      set -g __fish_git_prompt_color_cleanstate brgreen
    end

    printf '%s%s %s%s%s%s ' (set_color $fish_color_host) (prompt_hostname) (set_color $fish_color_cwd) (prompt_pwd) (set_color normal) (__fish_git_prompt)

    if not test $last_status -eq 0
      set_color $fish_color_error
    end
    echo -n '$ '
    set_color normal
  end
  '';

  xdg.configFile."fish/functions/gg.fish".text = ''
  function gg --description 'Alias for git grep'
    git grep $argv
  end
  '';

  xdg.configFile."fish/functions/mkcd.fish".text = ''
  function mkcd --description 'Create and enter a directory'
  	mkdir -p $argv[1]; and cd $argv[1];
  end
  '';

  xdg.configFile."fish/functions/expand-dot-to-parent-directory-path.fish".text = ''
  function expand-dot-to-parent-directory-path --description 'expand ... to ../.. etc'
    # Get commandline up to cursor
    set -l cmd (commandline --cut-at-cursor)

    # Match last line
    switch $cmd[-1]
      case '*..'
        commandline --insert '/..'
      case '*'
        commandline --insert '.'
    end
  end
  '';


  xdg.configFile."fish/functions/fzf-bcd-widget.fish".text = ''
  function fzf-bcd-widget --description 'cd backwards'
  	pwd | awk -v RS=/ '/\n/ {exit} {p=p $0 "/"; print p}' | tac | eval (__fzfcmd) +m --select-1 --exit-0 $FZF_BCD_OPTS | read -l result
  	[ "$result" ]; and cd $result
  	commandline -f repaint
  end
  '';

  xdg.configFile."fish/functions/fzf-cdhist-widget.fish".text = ''
  function fzf-cdhist-widget --description 'cd to one of the previously visited locatiosn'
  	# Clear non-existent folders from cdhist.
  	set -l buf
  	for i in (seq 1 (count $dirprev))
  		set -l dir $dirprev[$i]
  		if test -d $dir
  			set buf $buf $dir
  		end
  	end
  	set dirprev $buf
  	string join \n $dirprev | tac | sed 1d | eval (__fzfcmd) +m --tiebreak=index --toggle-sort=ctrl-r $FZF_CDHIST_OPTS | read -l result
  	[ "$result" ]; and cd $result
  	commandline -f repaint
  end
  '';

  xdg.configFile."fish/config.fish".text = ''
  function fish_user_key_bindings
    bind . 'expand-dot-to-parent-directory-path'
  end
  '';

  home.file.".gdbinit".text = ''
    set history save on
  '';

  home.file.".ghci".text = ''
    :set prompt "λ> "
  '';

  home.file."tobias.lco".text = ''
    \ProvidesFile{tobias.lco}

    \KOMAoptions{%
    % fromemail=true,       % Email wird im Briefkopf angezeigt
    % fromphone=true,       % Telefonnumer wird im Briefkopf angezeigt
    % fromfax=true,         % Faxnummer wird im Briefkopf angezeit
    % fromurl=true,         % URL wird im Briefkopf angezeigt
    % fromlogo=true,        % Logo wird im Briefkopf angezeigt
    % subject=titled,       % Druckt "Betrifft: " vor dem Betreff
    %locfield=wide,          % Breite Absenderergänzung (location)
    fromalign=left,         % Ausrichtung des Briefkopfes
    fromrule=afteraddress%  % Trennlinie unter dem Briefkopf
    }

    %\RequirePackage[utf8]{inputenc}
    \RequirePackage[ngerman]{babel}

    \setkomavar{fromname}{Tobias Mayer} % Name
    \setkomavar{fromaddress}{% % Adresse
      Ebertallee 39\\
      22607 Hamburg%
    }
    %\setkomavar{fromfax}{01234~56789} % Faxnummer
    %\setkomavar{fromemail}{max.muster@muster.com} % Email-Adresse
    %\setkomavar{fromphone}{01234~56789} % Telefonnummer
    %\setkomavar{fromurl}[Website:~]{www.muster.com} % Website

    % ===== Absenderergänzung =====
    %\setkomavar{location}{%
    %  \raggedright\footnotesize{%
    %  \usekomavar{fromname}\\
    %  \usekomavar{fromaddress}\\
    %  \usekomavar*{fromphone}\usekomavar{fromphone}\\
    %  \usekomavar*{fromfax}\usekomavar{fromfax}\\
    %  \usekomavar*{fromemail}\usekomavar{fromemail}
    %  \usekomavar*{fromurl}\usekomavar{fromurl}}%
    %}
    % ============================

    % Logo
    % \setkomavar{fromlogo}{\includegraphics{logo.png}}

    % Die Bankverbindung wird nicht automatisch verwendet. Dazu muss bspw. mittels \firstfoot ein eigener Brieffuß definiert werden.
    %\setkomavar{frombank}{}

    % ===== Signatur =====
    %\setkomavar{signature}{%
      %\usekomavar{fromname}\\
      %Geschäftsführer%
    %}
    %\renewcommand*{\raggedsignature}{\raggedright}
    % ====================
  '';

  programs.home-manager.enable = true;
  programs.home-manager.path = https://github.com/rycee/home-manager/archive/master.tar.gz;
}
