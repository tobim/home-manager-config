{ pkgs, lib, config, ... }:

let
    on_darwin = builtins.currentSystem == "x86_64-darwin";
    on_linux = builtins.currentSystem == "x86_64-linux";
    gst_packages = with pkgs.gst_all_1; [
      gstreamer
      gst-plugins-good
      gst-plugins-bad
      gst-plugins-ugly
      #gst-ffmpeg
    ];

    notesDir = "/home/tobim/zettelkasten";
    neuron = (
      let neuronRev = "687dcf0bec94c238361db64b08b4fac62bee89dd";
          neuronSrc = builtins.fetchTarball "https://github.com/srid/neuron/archive/${neuronRev}.tar.gz";
       in import neuronSrc {});

    #doom-emacs = pkgs.callPackage (builtins.fetchTarball {
    #    url = https://github.com/vlaci/nix-doom-emacs/archive/master.tar.gz;
    #  }) {
    #    doomPrivateDir = ./doom.d;  # Directory containing your config.el init.el
    #                                # and packages.el files
    #  };

    weechat-notify = pkgs.weechat.override {
      configure = { availablePlugins, ... }: {
        scripts = with pkgs.weechatScripts; [
          weechat-notify-send wee-slack
        ];
      };
    };
    weechat = pkgs.weechat;

    fonts = with pkgs; [
      anonymousPro
      dejavu_fonts
      font-awesome
      hack-font
      ia-writer-duospace
      #nerdfonts
      proggyfonts
      roboto-mono
      source-code-pro
      #unscii
    ];

    linux_packages = [
      #pkgs.aqbanking
      pkgs.chromium
      pkgs.dtrx
      pkgs.gnome3.glib-networking
      pkgs.gnome3.gnome-tweak-tool
      pkgs.gparted
      pkgs.meld
      pkgs.numix-cursor-theme
      pkgs.numix-icon-theme
      pkgs.pinentry_gnome
      pkgs.qutebrowser
      #pkgs.waybar
      pkgs.wl-clipboard
      pkgs.xournalpp
      #haskellPackages.buchhaltung
    ] ++ gst_packages;

    darwin_packages = with pkgs.darwin.apple_sdk; [
      frameworks.Security
      frameworks.CoreFoundation
      frameworks.CoreServices
    ];

    home_packages = with pkgs; [
      #doom-emacs
      neuron
      pkgs.beets
      pkgs.hledger
      pkgs.ncmpcpp
      pkgs.pavucontrol
      pkgs.playerctl
      pkgs.signal-desktop
      pkgs.slack
      pkgs.teams
      pkgs.wmc-mpris
      pkgs.youtube-dl
      pkgs.zoom-us
    ];

    py3 = pkgs.python3.withPackages(ps: with ps; [
      black
      flake8
      pylint
      yapf
      pyflakes
      pyls-isort
      pylsp-mypy
      python-lsp-black
      python-lsp-server
      rope
    ]);

    default_packages = [
      py3
      pkgs._1password
      pkgs.alacritty
      pkgs.any-nix-shell
      pkgs.bandwhich
      pkgs.bat
      pkgs.cachix
      pkgs.cargo
      pkgs.ccache
      pkgs.ccls
      pkgs.cmake
      pkgs.clang-tools
      pkgs.coreutils
      pkgs.direnv
      pkgs.exa
      pkgs.fd
      pkgs.file
      pkgs.fishPlugins.foreign-env
      #pkgs.fishPlugins.done
      pkgs.fzf
      pkgs.gcsfuse
      pkgs.git
      pkgs.gitAndTools.git-gone
      pkgs.gitAndTools.git-imerge
      pkgs.gitAndTools.git-recent
      pkgs.gitAndTools.git-trim
      pkgs.gitAndTools.gh
      pkgs.git-revise
      pkgs.gnumake
      pkgs.htop
      pkgs.imagemagick
      pkgs.isync
      pkgs.jq
      pkgs.lnav
      pkgs.nixpkgs-fmt
      pkgs.ncdu
      pkgs.neovim-remote
      pkgs.ninja
      pkgs.notmuch
      pkgs.parallel
      pkgs.pass
      pkgs.passff-host
      pkgs.psmisc
      pkgs.ripgrep
      pkgs.rnix-lsp
      pkgs.rust-analyzer
      pkgs.rustc
      pkgs.syncthing
      pkgs.taskwarrior
      pkgs.tectonic
      pkgs.tmux
      pkgs.tokei
      pkgs.tree
      pkgs.pyright
      weechat
    ];

    #python_packages = let
    #  python = let
    #    packageOverrides = final: prev: {
    #      pyls-black = prev.pyls-black.override {
    #        python-language-server = final.python-lsp-server;
    #      };
    #      pyls-mypy = prev.pyls-mypy.override {
    #        python-language-server = final.python-lsp-server;
    #      };
    #    };
    #  in pkgs.python3.override {inherit packageOverrides; self = python;};
    #in [
    #  python.withPackages (ps: with ps; [
    #    black
    #    flake8
    #    pylint
    #    yapf
    #    pyflakes
    #    pyls-mypy
    #    pyls-isort
    #    python-lsp-server
    #    python-lsp-black
    #    rope
    #  ])
    #];

in
{
  nixpkgs.overlays = [ 
    (import (builtins.fetchTarball {
      url = https://github.com/mjlbach/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  imports = [ ./modules/neovim-nightly.nix ];

  home = {
    stateVersion = "21.03";
    username = "tobim";
    homeDirectory = "/home/tobim";
    packages = default_packages ++ fonts ++
      (if on_linux then linux_packages ++ home_packages
      else if on_darwin then darwin_packages
      else []);

    sessionVariables = {
      BLOCK_SIZE = "'1";
      BROWSER = "firefox";
      VISUAL = "nn";
      EDITOR = "nn";
      GS_OPTIONS = "-sPAPERSIZE=a4";
      # Prevent clobbering SSH_AUTH_SOCK
      GSM_SKIP_SSH_AGENT_WORKAROUND = "1";
      CMAKE_CXX_COMPILER_LAUNCHER="ccache";
    } // lib.optionalAttrs on_darwin {
      SSH_AUTH_SOCK = "\${SSH_AUTH_SOCK:-$(gpgconf --list-dirs agent-ssh-socket)}";
    };
  };

  accounts.email.accounts = {
    fastmail = {
      primary = true;
      address = "tobim@fastmail.fm";
      mbsync = {
        enable = true;
        create = "maildir";
        expunge = "both";
      };
    };
  };

  pam.sessionVariables = {
    EDITOR = "nn";
  };

  # Disable gnome-keyring ssh-agent
  xdg.configFile."autostart/gnome-keyring-ssh.desktop".text = if on_linux then ''
    ${pkgs.lib.fileContents "${pkgs.gnome3.gnome-keyring}/etc/xdg/autostart/gnome-keyring-ssh.desktop"}
    Hidden=true
  '' else "";

  programs.gpg = {
    enable = true;
  };

  services.gpg-agent = {
    enable = on_linux;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
    enableExtraSocket = true;
    extraConfig = ''
      extra-socket /home/tobim/.gnupg/S.gpg-agent.extra
      pinentry-program ${pkgs.pinentry_gnome}/bin/pinentry-gnome3
    '';
  };

  services.kbfs.enable = true;
  services.keybase.enable = true;

  fonts.fontconfig.enable = true;

  services.syncthing.enable = on_linux;

  programs.firefox = {
    enable = !on_darwin;
    package = pkgs.firefox-wayland;
    #package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
    #  extraPolicies = {
    #    ExtensionSettings = {};
    #  };
    #};
  };
  programs.browserpass.enable = true;

  programs.fish = {
    enable = true;

    shellAbbrs = {
      gg = "git grep";
      gd = "git diff";
      gl = "git slog";
    };

    shellAliases = {
      gs = "git st";
    } // lib.optionalAttrs on_linux {
      ip = "ip -br -c";
    };

    plugins = [
      {
        name = "z";
        src = pkgs.fetchFromGitHub {
          owner = "franciscolourenco";
          repo = "done";
          rev = "1.16.1";
          sha256 = "09m8sjnlhagv44hk0vmh48q6kdmv9mb55v3gcpbkb02r6hmsqp1l";
        };
      }
    ];

    interactiveShellInit = ''
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

      function mkcd --description 'Create and enter a directory'
        mkdir -p $argv[1]; and cd $argv[1];
      end

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
      function fish_user_key_bindings
        bind . 'expand-dot-to-parent-directory-path'
      end

      any-nix-shell fish --info-right | source
    '';
  };

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    #initExtra = ''
    #  source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    #  source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/config/p10k-lean.zsh
    #'';
    autocd = true;
    dotDir = ".config/zsh";
    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
    };
    initExtra = ''
      any-nix-shell zsh --info-right | source /dev/stdin
    '';
  };

  programs.starship = {
    enable = true;

    enableZshIntegration = true;
    enableFishIntegration = false;

    settings = {
      #add_newline = false;
      #format = lib.concatStrings [
      #  "$line_break"
      #  "$package"
      #  "$line_break"
      #  "$character"
      #];
      #scan_timeout = 10;
      #character = {
      #  success_symbol = "➜";
      #  error_symbol = "➜";
      #};
    };
  };

  programs.git = {
    enable = true;
    userName = "Tobias Mayer";
    userEmail = "tobim@fastmail.fm";
    signing = {
      key = "F8657E90819A1298";
      signByDefault = true;
    };
    aliases = {
      st = "status --short --branch";
      amend =    "commit --amend";
      undo =     "reset --soft HEAD^";
      tracking = "!f() { git for-each-ref --format='%(upstream:short)' \"$(git rev-parse --symbolic-full-name \${1:-HEAD})\"; }; f";
      raze =     "!f() { git reset --hard \"$(git tracking)\"; }; f";
      parent =   "!f() { git show-branch | grep '*' | grep -v \"$(git rev-parse --abbrev-ref HEAD)\" | head -n1 | sed 's/.*\\[\\(.*\\)\\].*/\\1/' | sed 's/[\\^~].*//'; }; 2>/dev/null f ";
      base = "!f() { git merge-base $(git parent) HEAD; }; f";
      recommit = "!f() { git commit -eF \"$(git rev-parse --git-dir)/COMMIT_EDITMSG\"; }; f";
      glog =     "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'";
      grog =     "log --graph --abbrev-commit --decorate --all --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(dim white) - %an%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n %C(white)%s%C(reset)'";
      slog =     "!f() { git log --pretty=\"%C(yellow)%h%Creset %s %Cred%d%Creset\" $(git base)..; }; f";
      sub = "!f() { git grep -l $1 | xargs sed -i 's|$1|$2|g'; }; f";
      news = "!f() { git log --merges --format=\"%C(green)%cr%C(reset) %C(yellow)%h%C(reset) %b%C(#CFCFCF)%+N%C(reset)\" \"\$(git describe --first-parent --abbrev=0)\".. \"\$@\"; }; f";
      #base = "!f() { git reflog --no-abbrev --all | grep \"refs/heads/$(git name-rev --name-only HEAD)@{[0-9]\+}: branch: Created from\" | cut -d' ' -f 1; }; f";

    };
    extraConfig = {
      merge.tool = "vimdiff";
      mergetool.prompt = true;
      "mergetool \"vimdiff\"".cmd = "nn -d $BASE $LOCAL $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'";
      transfer.fschkobjects = true;
      pull.ff = "only";
    };
    ignores = [
      ".cache/"
      ".ccls-cache/"
      ".clangd/"
      ".direnv/"
    ];
  };

  programs.emacs = {
    enable = true;
    extraPackages = epkgs: [
      epkgs.magit
      epkgs.evil
      epkgs.evil-org
      epkgs.which-key
    ];
  };

  home.file."${config.xdg.configHome}/nvim/parser/bash.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-bash}/parser";
  home.file."${config.xdg.configHome}/nvim/parser/cpp.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-cpp}/parser";
  home.file."${config.xdg.configHome}/nvim/parser/haskell.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-haskell}/parser";
  home.file."${config.xdg.configHome}/nvim/parser/json.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-json}/parser";
  home.file."${config.xdg.configHome}/nvim/parser/markdown.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-markdown}/parser";
  home.file."${config.xdg.configHome}/nvim/parser/nix.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-nix}/parser";
  home.file."${config.xdg.configHome}/nvim/parser/python.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-python}/parser";
  home.file."${config.xdg.configHome}/nvim/parser/rust.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-rust}/parser";
  home.file."${config.xdg.configHome}/nvim/parser/toml.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-toml}/parser";
  home.file."${config.xdg.configHome}/nvim/parser/yaml.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-yaml}/parser";
  home.file."${config.xdg.configHome}/nvim/parser/zig.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-zig}/parser";
  programs.neovim = import ./neovim {inherit pkgs;};
  programs.neovim-nightly = import ./neovim/nightly.nix {inherit pkgs;};

  programs.mpv = {
    enable = false;
  };

  programs.gnome-terminal = if on_linux then {
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
  include $${HOME}/misc/base16-kitty/base16-gruvbox-dark-medium-256.conf

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

  services.lorri.enable = true;

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
  };

  #systemd.user.services.neuron = {
  #  Unit.Description = "Neuron zettelkasten service";
  #  Install.WantedBy = [ "graphical-session.target" ];
  #  Service = {
  #    ExecStart = "${neuron}/bin/neuron -d ${notesDir} rib -wS";
  #  };
  #};

  home.file.".gdbinit".text = ''
    set history save on
    set history filename $HOME/.local/var/gdb_history
  '';

  home.file.".ghci".text = ''
    :set prompt "λ> "
  '';

  home.file.".taskrc".text = ''
  data.location=~/.task

  # Color theme (uncomment one to use)
  #include /usr/share/doc/task/rc/light-16.theme

  taskd.server=freecinc.com:53589
  taskd.key=\/home\/tobim\/.task\/freecinc_8a28343b.key.pem
  taskd.certificate=\/home\/tobim\/.task\/freecinc_8a28343b.cert.pem
  taskd.ca=\/home\/tobim\/.task\/freecinc_8a28343b.ca.pem
  taskd.credentials=FreeCinc\/freecinc_8a28343b\/453877b4-3a6f-4cbe-9cab-051435fa5827
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
} // lib.optionalAttrs on_darwin {
  xdg.configFile."homebrew/brewfile".text = ''
    tap "homebrew/core"
    tap "homebrew/bundle"
    tap "homebrew/services"
    tap "caskroom/cask"

    brew "pinentry-mac"

    cask "1password"
    cask "docker"
    cask "firefox"
    cask "google-drive-file-stream"
    cask "hammerspoon"
    cask "kitty"
    cask "qlcolorcode"
    cask "qlimagesize"
    cask "qlmarkdown"
    cask "qlprettypatch"
    cask "qlstephen"
    cask "quicklook-csv"
    cask "quicklook-json"
    cask "slack"
    cask "suspicious-package"
    cask "virtualbox"
    cask "virtualbox-extension-pack"
    cask "zoomus"
  '';
  xdg.configFile."wireguard/wg0.conf".text = ''
    [Interface]
    Address = 10.100.0.3
    PostUp = wg set %i private-key <(pass wireguard/tenzir-darwin/private/%i)
    ListenPort = 51820
    [Peer]
    PublicKey = e1CJc1Nkprw5g9KNRNokoqWFEfnFi+nO6wMAm/CjDWI=
    AllowedIPs = 0.0.0.0
    Endpoint = p5sjwjau98.crabdance.com:51820
    # This is for if you’re behind a NAT and want the connection to be kept alive.
    PersistentKeepalive = 25
  '';
}
