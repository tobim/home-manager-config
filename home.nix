{ pkgs, lib, config, ... }:

let
    clangPredicate = n: _: with pkgs.lib; with builtins;
      hasPrefix "clang_" n && !(hasPrefix "clang_3" n);
    clangs = pkgs.lib.filterAttrs clangPredicate pkgs
      // { inherit (pkgs) clang; };

    clang-tools-wrapper = let
      wrapCC = cc: pkgs.callPackage ./clang-tools-wrapper.nix {
        inherit cc;
      };
    in pkgs.lib.mapAttrs (_: v: wrapCC v) clangs // {
      inherit wrapCC;
      recurseForDerivations = true;
    };

    on_darwin = builtins.currentSystem == "x86_64-darwin";
    on_linux = builtins.currentSystem == "x86_64-linux";
    gst_packages = with pkgs; [
      gstreamer
      gst-plugins-good
      gst-plugins-bad
      gst-plugins-ugly
      #gst-ffmpeg
    ];

    fonts = with pkgs; [
      anonymousPro
      dejavu_fonts
      font-awesome
      hack-font
      ia-writer-duospace
      nerdfonts
      proggyfonts
      roboto-mono
      source-code-pro
      unscii
    ];

    linux_packages = [
      pkgs.aqbanking
      pkgs.chromium
      pkgs.dtrx
      pkgs.gnome3.glib-networking
      pkgs.gparted
      pkgs.kbfs
      pkgs.meld
      pkgs.numix-cursor-theme
      pkgs.numix-icon-theme
      pkgs.qutebrowser
      pkgs.waybar
      pkgs.wl-clipboard
      pkgs.xournal
      #haskellPackages.buchhaltung
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
      #pkgs.zoom-us
    ];

    default_packages = [
      pkgs.alacritty
      pkgs.any-nix-shell
      pkgs.ccls
      pkgs.cmake
      clang-tools-wrapper.clang_8
      #pkgs.clang-tools
      pkgs.cloc
      pkgs.coreutils
      pkgs.direnv
      pkgs.exa
      pkgs.fd
      pkgs.file
      pkgs.fish-foreign-env
      pkgs.fzf
      pkgs.git
      pkgs.gitAndTools.git-gone
      pkgs.gitAndTools.git-recent
      pkgs.gitAndTools.hub
      pkgs.git-revise
      pkgs.gnumake
      pkgs.pinentry_ncurses
      pkgs.htop
      pkgs.imagemagick
      pkgs.isync
      pkgs.jq
      pkgs.keybase
      pkgs.lnav
      pkgs.nixfmt
      pkgs.nixpkgs-fmt
      pkgs.ncdu
      pkgs.neovim-remote
      pkgs.ninja
      pkgs.notmuch
      pkgs.pass
      pkgs.passff-host
      pkgs.ripgrep
      pkgs.syncthing
      pkgs.taskwarrior
      pkgs.tectonic
      pkgs.tmux
      pkgs.tree
    ];

    python_packages = [
      (pkgs.python3.withPackages (ps: with ps; [
        black
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


in
{
  home = {
    packages = default_packages ++ python_packages ++ fonts ++
      (if on_linux then linux_packages ++ home_packages
      else if on_darwin then darwin_packages
      else []);

    sessionVariables = {
      BLOCK_SIZE = "'1";
      VISUAL = "nvim";
      EDITOR = "nvim";
      GS_OPTIONS = "-sPAPERSIZE=a4";
      # Prevent clobbering SSH_AUTH_SOCK
      GSM_SKIP_SSH_AGENT_WORKAROUND = "1";

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
    EDITOR = "nvim";
  };

  # Disable gnome-keyring ssh-agent
  xdg.configFile."autostart/gnome-keyring-ssh.desktop".text = if on_linux then ''
    ${pkgs.stdenv.lib.fileContents "${pkgs.gnome3.gnome-keyring}/etc/xdg/autostart/gnome-keyring-ssh.desktop"}
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
    '';
  };

  fonts.fontconfig.enable = true;

  services.syncthing.enable = on_linux;

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-wayland;
  };
  programs.browserpass.enable = true;

  programs.fish = {
    enable = true;

    shellAbbrs = {
      gg = "git grep";
    };

    shellAliases = lib.optionalAttrs on_linux {
      ip = "ip -br -c";
    };

    promptInit = ''
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

    interactiveShellInit = ''
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
  };

  programs.git = {
    enable = true;
    userName = "Tobias Mayer";
    userEmail = "tobim@fastmail.fm";
    aliases = {
      st = "status --short --branch ";
      ci = "commit ";
      bclean = ''
        "!f() { \
           force=F;\
           while getopts \"f\" opt; do\
             case \"$opt\" in f) force=T;;\
             esac;\
           done;\
           shift $(expr $OPTIND - 1);\
           cmd=(-L 1 echo);\
           if [ \"$force\" = \"T\" ]; then\
             cmd=(git branch -d);\
           fi;\
           git branch --merged ''${1-master} | grep -v \" ''${1-master}$\" | xargs -r ''${cmd[@]}; };\
         f"'';
      amend = "commit --amend ";
      undo = "reset --soft HEAD^ ";
      glog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' ";
      grog = "log --graph --abbrev-commit --decorate --all --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(dim white) - %an%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n %C(white)%s%C(reset)' ";
      #sub = "!f() { git grep -l $1 | xargs sed -i 's|$1|$2|g' }; f"
    };
    extraConfig=''
      [merge]
        tool = vimdiff
      [mergetool]
        prompt = true
      [mergetool "vimdiff"]
        cmd = nvim -d $BASE $LOCAL $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'
      [transfer]
        fschkobjects = true
    '';
    ignores = [
      ".direnv/"
    ];
  };

  programs.neovim = import ./neovim.nix {inherit pkgs;};

  programs.mpv = {
    enable = true;
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

  programs.direnv = {
    enable = true;
    stdlib = ''
      # Usage: use_nix [...]
      #
      # Load environment variables from `nix-shell`.
      # If you have a `default.nix` or `shell.nix` one of these will be used and
      # the derived environment will be stored at ./.direnv/env-<hash>
      # and symlink to it will be created at ./.direnv/default.
      # Dependencies are added to the GC roots, such that the environment remains persistent.
      #
      # Packages can also be specified directly via e.g `use nix -p ocaml`,
      # however those will not be added to the GC roots.
      #
      # The resulting environment is cached for better performance.
      #
      # To trigger switch to a different environment:
      # `rm -f .direnv/default`
      #
      # To derive a new environment:
      # `rm -rf .direnv/env-$(md5sum {shell,default}.nix 2> /dev/null | cut -c -32)`
      #
      # To remove cache:
      # `rm -f .direnv/dump-*`
      #
      # To remove all environments:
      # `rm -rf .direnv/env-*`
      #
      # To remove only old environments: 
      # `find .direnv -name 'env-*' -and -not -name `readlink .direnv/default` -exec rm -rf {} +`
      #
      use_nix() {
          set -e

          local shell="shell.nix"
          if [[ ! -f "''${shell}" ]]; then
              shell="default.nix"
          fi

          if [[ ! -f "''${shell}" ]]; then
              fail "use nix: shell.nix or default.nix not found in the folder"
          fi

          local dir="''${PWD}"/.direnv
          local default="''${dir}/default"
          if [[ ! -L "''${default}" ]] || [[ ! -d `readlink "''${default}"` ]]; then
              local wd="''${dir}/env-`md5sum "''${shell}" | cut -c -32`" # TODO: Hash also the nixpkgs version?
              mkdir -p "''${wd}"

              local drv="''${wd}/env.drv"
              if [[ ! -f "''${drv}" ]]; then
                  log_status "use nix: deriving new environment"
                  IN_NIX_SHELL=1 nix-instantiate --add-root "''${drv}" --indirect "''${shell}" > /dev/null
                  nix-store -r `nix-store --query --references "''${drv}"` --add-root "''${wd}/dep" --indirect > /dev/null
              fi

              rm -f "''${default}"
              ln -s `basename "''${wd}"` "''${default}"
          fi

          local drv=`readlink -f "''${default}/env.drv"`
          local dump="''${dir}/dump-`md5sum ".envrc" | cut -c -32`-`md5sum ''${drv} | cut -c -32`"

          if [[ ! -f "''${dump}" ]] || [[ "''${XDG_CONFIG_DIR}/direnv/direnvrc" -nt "''${dump}" ]]; then
              log_status "use nix: updating cache"

              old=`find "''${dir}" -name 'dump-*'`
              nix-shell "''${drv}" --show-trace "$@" --run 'direnv dump' > "''${dump}"
              rm -f ''${old}
          fi

          direnv_load cat "''${dump}"

          watch_file "''${default}"
          watch_file shell.nix
          if [[ ''${shell} == "default.nix" ]]; then
              watch_file default.nix
          fi
      }
    '';
    enableFishIntegration = true;
  };

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
