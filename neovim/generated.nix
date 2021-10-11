# This file has been generated by ./pkgs/misc/vim-plugins/update.py. Do not edit!
{ lib, buildVimPluginFrom2Nix, fetchFromGitHub, overrides ? (self: super: {}) }:

let
  packages = ( self:
{
  completion-nvim = buildVimPluginFrom2Nix {
    pname = "completion-nvim";
    version = "2021-04-08";
    src = fetchFromGitHub {
      owner = "nvim-lua";
      repo = "completion-nvim";
      rev = "8bca7aca91c947031a8f14b038459e35e1755d90";
      sha256 = "02zqc75p9ggrz6fyiwvzpnzipfd1s5xfr7fli2yypb4kp72mrbaf";
    };
  };

  distilled-vim = buildVimPluginFrom2Nix {
    pname = "distilled-vim";
    version = "2020-09-18";
    src = fetchFromGitHub {
      owner = "KKPMW";
      repo = "distilled-vim";
      rev = "a3d366af10b3ac477af2c9225c57ec630b416381";
      sha256 = "182xcmlb10h611m0awrbj41pz5phn2smvclzn9rajzal4ihwlg2g";
    };
  };

  flatlandia = buildVimPluginFrom2Nix {
    pname = "flatlandia";
    version = "2014-05-05";
    src = fetchFromGitHub {
      owner = "jordwalke";
      repo = "flatlandia";
      rev = "05069c3777c463b25b609dca8dccacf9f75e2ce3";
      sha256 = "04mk80zaxjxh9hdy9ll12ri9pq6s0p0lz1myg7yfz8rgyd74kaqz";
    };
  };

  git-messenger-vim = buildVimPluginFrom2Nix {
    pname = "git-messenger-vim";
    version = "2021-05-14";
    src = fetchFromGitHub {
      owner = "rhysd";
      repo = "git-messenger.vim";
      rev = "2a26734c6322449a56d02c25a2947e9b7519ca49";
      sha256 = "0ib0yl7zqklj9i1sgv854d3xl5sqbdf2khh9cpraik1rv23nlf2h";
    };
  };

  iceberg-vim = buildVimPluginFrom2Nix {
    pname = "iceberg-vim";
    version = "2020-12-25";
    src = fetchFromGitHub {
      owner = "cocopon";
      repo = "iceberg.vim";
      rev = "866f9f4ac9ff9a0ae33de96253c359c68ab556b4";
      sha256 = "1zlj85xg8r8qbnr7dpszkcjqw70xahay7ydwnik0zwhq96mic1pv";
    };
  };

  nova-vim = buildVimPluginFrom2Nix {
    pname = "nova-vim";
    version = "2019-08-27";
    src = fetchFromGitHub {
      owner = "trevordmiller";
      repo = "nova-vim";
      rev = "e587d14c655a4d2d048556eaaa5419a14f17826a";
      sha256 = "0qdr84iykm8jrfl5q4clqv335blp3lj57isg0ylz1wak1gkn9dx8";
    };
  };

  nvim-lspconfig = buildVimPluginFrom2Nix {
    pname = "nvim-lspconfig";
    version = "2021-05-28";
    src = fetchFromGitHub {
      owner = "neovim";
      repo = "nvim-lspconfig";
      rev = "9b4c71f98130e850b6ebb2e78b0500de7f355b1a";
      sha256 = "096b1ihl7j7l9h839cy4hg7hqk5d2w7w6q4a7w6g2wnyz9p7q37j";
    };
  };

  nvim-treesitter = buildVimPluginFrom2Nix {
    pname = "nvim-treesitter";
    version = "2021-05-28";
    src = fetchFromGitHub {
      owner = "nvim-treesitter";
      repo = "nvim-treesitter";
      rev = "972f70956ac8635ab2f6d7ed0b24e5cd159d7a04";
      sha256 = "1ahndi9yqd91jp1fd7vxi04bmanpyrxs48r9j8l7snl7l91gsy71";
    };
  };

  vim-altr = buildVimPluginFrom2Nix {
    pname = "vim-altr";
    version = "2019-05-24";
    src = fetchFromGitHub {
      owner = "kana";
      repo = "vim-altr";
      rev = "fba055cf3b83a1ada5b05d694fbefd024aa93289";
      sha256 = "0q1zzfmzq1r6lfif2apx0pb82pa7ar84fyxl6l8dkal2712rsr5w";
    };
  };

  vim-clang-format = buildVimPluginFrom2Nix {
    pname = "vim-clang-format";
    version = "2019-05-15";
    src = fetchFromGitHub {
      owner = "rhysd";
      repo = "vim-clang-format";
      rev = "95593b67723f23979cd7344ecfd049f2f917830f";
      sha256 = "0n0k13k63l8n0ixs4zrhlz923apvdp2mldadxqlhmvsvncmlqmpn";
    };
  };

  vim-clap = buildVimPluginFrom2Nix {
    pname = "vim-clap";
    version = "2021-05-28";
    src = fetchFromGitHub {
      owner = "liuchengxu";
      repo = "vim-clap";
      rev = "2de6a5fdb8be27d848638445ce6bd2cfca921d82";
      sha256 = "18fmkx3d6y4g4q6iydv19gh1qkhgkpn4ns6mlz52a720w3q1cy69";
    };
  };

  vim-pasta = buildVimPluginFrom2Nix {
    pname = "vim-pasta";
    version = "2018-09-08";
    src = fetchFromGitHub {
      owner = "sickill";
      repo = "vim-pasta";
      rev = "cb4501a123d74fc7d66ac9f10b80c9d393746c66";
      sha256 = "14rswwx24i75xzgkbx1hywan1msn2ki26353ly2pyvznnqss1pwq";
    };
  };

  vim-substrata = buildVimPluginFrom2Nix {
    pname = "vim-substrata";
    version = "2021-03-23";
    src = fetchFromGitHub {
      owner = "arzg";
      repo = "vim-substrata";
      rev = "f7b71f31d2ffa91715964b14b41ad4009d4d97f6";
      sha256 = "1cpmyr63xjx5nm5h619xwryjaljq1kdf3msdrdr082ljci2830z2";
    };
  };

  vim-textobj-variable-segment = buildVimPluginFrom2Nix {
    pname = "vim-textobj-variable-segment";
    version = "2019-12-30";
    src = fetchFromGitHub {
      owner = "Julian";
      repo = "vim-textobj-variable-segment";
      rev = "78457d4322b44bf89730e708b62b69df48c39aa3";
      sha256 = "14dcrnk83hj4ixrkdgjrk9cf0193f82wqckdzd4w0b76adf3habj";
    };
  };

  vim-visual-star-search = buildVimPluginFrom2Nix {
    pname = "vim-visual-star-search";
    version = "2020-06-19";
    src = fetchFromGitHub {
      owner = "bronson";
      repo = "vim-visual-star-search";
      rev = "e48c3fe596230e38f5a0e5313455e835c14aeb6a";
      sha256 = "1fmfsalmj5qam439rv5wm11az53ql9h5ikg0drx3kp8d5b6fcr9c";
    };
  };

  vimagit = buildVimPluginFrom2Nix {
    pname = "vimagit";
    version = "2020-11-18";
    src = fetchFromGitHub {
      owner = "jreybert";
      repo = "vimagit";
      rev = "aaf1278f03e866f0b978d4b0f0cc7084db251129";
      sha256 = "1k23q1p6wgjlk1cpmv1ijjggjklz8hgg6s7bx6mrk0aw5j2s1pdh";
    };
  };

  vista-vim = buildVimPluginFrom2Nix {
    pname = "vista-vim";
    version = "2021-05-28";
    src = fetchFromGitHub {
      owner = "liuchengxu";
      repo = "vista.vim";
      rev = "19cad968d2cd759e7f9de1d662ec680bd93ebebc";
      sha256 = "0r01b6mml6qgyybi6i59bflgqi03w0fnl0wfgwac96ixs2wdvl1l";
    };
  };

});
in lib.fix' (lib.extends overrides packages)
