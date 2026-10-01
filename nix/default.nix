# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
/*
  # paste the inputs you don't have in this set into your main system flake.nix
  # (lazy.nvim wrapper only works on unstable)
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
  };

  Then call this file with:
  myNixCats = import ./path/to/this/dir { inherit inputs; };
  And the new variable myNixCats will contain all outputs of the normal flake format.
  You could put myNixCats.packages.${pkgs.stdenv.hostPlatform.system}.thepackagename in your packages list.
  You could install them with the module and reconfigure them too if you want.
  You should definitely re export them under packages.${system}.packagenames
  from your system flake so that you can still run it via nix run from anywhere.

  The following is just the outputs function from the flake template.
*/
{ inputs, ... }@attrs:
let
  inherit (inputs) nixpkgs; # <-- nixpkgs = inputs.nixpkgsSomething;
  inherit (inputs.nixCats) utils;
  luaPath = ../.;
  forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;
  # the following extra_pkg_config contains any values
  # which you want to pass to the config set of nixpkgs
  # import nixpkgs { config = extra_pkg_config; inherit system; }
  extra_pkg_config = {
    allowUnfree = true;
  };
  dependencyOverlays = # (import ./overlays inputs) ++
    [
      # see :help nixCats.flake.outputs.overlays
      # This overlay grabs all the inputs named in the format
      # `plugins-<pluginName>`
      # Once we add this overlay to our nixpkgs, we are able to
      # use `pkgs.neovimPlugins`, which is a set of our plugins.
      (utils.sanitizedPluginOverlay inputs)
      # add any flake overlays here.

      # when other people mess up their overlays by wrapping them with system,
      # you may instead call this function on their overlay.
      # it will check if it has the system in the set, and if so return the desired overlay
      # (utils.fixSystemizedOverlay inputs.codeium.overlays
      #   (system: inputs.codeium.overlays.${system}.default)
      # )
      (final: prev: {
        laravel-ls = final.callPackage ./laravel-ls.nix { };
      })
    ];

  categoryDefinitions =
    {
      pkgs,
      settings,
      categories,
      extra,
      name,
      mkPlugin,
      ...
    }@packageDef:
    {

      lspsAndRuntimeDeps = {
        general = with pkgs; [
          perl5Packages.NeovimExt
          python315Packages.pynvim
          neovim-node-client
          ripgrep
          fzf
        ];

        git = with pkgs; [
          git
        ];

        codesnap = with pkgs; [
          codesnap
        ];

        conform = with pkgs; [
          stylua
          prettier
        ];

        lsp = with pkgs; [
          lua-language-server
          typescript-language-server
          typescript-go
          yaml-language-server
          vscode-langservers-extracted
          nixd
          copilot-language-server
          astro-language-server
          tailwindcss-language-server
          shopify-cli
          intelephense
          laravel-ls
          tombi
        ];

        sops = with pkgs; [
          sops
        ];

        treesitter = with pkgs; [
          (
            let
              src = pkgs.fetchFromGitHub {
                owner = "tree-sitter";
                repo = "tree-sitter";
                tag = "v0.26.3";
                hash = "sha256-G1C5IhRIVcWUwEI45ELxCKfbZnsJoqan7foSzPP3mMg="; # Replace with actual hash after first build attempt
                fetchSubmodules = true;
              };

              name = "tree-sitter";
              version = "0.26.3";
            in
            tree-sitter.overrideAttrs (oldAttrs: {
              inherit version;

              inherit src;

              cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
                inherit src;
                name = "${name}-${version}-vendor";
                hash = "sha256-kHYLaiCHyKG+DL+T2s8yumNHFfndrB5aWs7ept0X4CM=";
              };

              buildInputs = [
                pkgs.libclang
              ]
              ++ oldAttrs.buildInputs;

              nativeBuildInputs = [
                pkgs.rustPlatform.bindgenHook
              ]
              ++ oldAttrs.nativeBuildInputs;

              patches = [ ];
            })
          )
        ];

        vectorcode = with pkgs; [
          vectorcode
        ];

        zk = with pkgs; [
          zk
        ];
      };

      startupPlugins = {
        general =
          (with pkgs.vimPlugins; [
            plenary-nvim
          ])
          ++ (with pkgs.neovimPlugins; [
            lze
          ]);

        lsp = with pkgs.vimPlugins; [
          nvim-lspconfig
        ];

        treesitter = pkgs.vimPlugins.nvim-treesitter;

        themer =
          let
            defaultScheme = "default";
            scheme = packageDef.categories.colorscheme or defaultScheme;

            schemes = with pkgs.vimPlugins; {
              "default" = [ ];
              "gruvbox" = gruvbox-nvim;
              "tokyonight" = tokyonight-nvim;
              "onedark" = onedark-nvim;
              "catppuccin" = catppuccin-nvim;
            };
          in
          (pkgs.lib.attrByPath [ scheme ] schemes.${defaultScheme} schemes);

        auto-session = pkgs.vimPlugins.auto-session;
        dashboard = pkgs.vimPlugins.alpha-nvim;
        oil = pkgs.vimPlugins.oil-nvim;
      };

      optionalPlugins = {
        git = with pkgs.vimPlugins; [
          vim-fugitive
          vim-rhubarb
          vim-git
          gitsigns-nvim
        ];

        general = with pkgs.vimPlugins; [ ];

        lsp = with pkgs.vimPlugins; [
          lazydev-nvim
        ];

        abolish = pkgs.vimPlugins.vim-abolish;
        arrow = pkgs.vimPlugins.arrow-nvim;
        autopairs = with pkgs.vimPlugins; [
          nvim-autopairs
          nvim-ts-autotag
        ];
        blink = with pkgs; [
          vimPlugins.blink-cmp
          neovimPlugins.blink-cmp-git
          neovimPlugins.blink-emoji-nvim
        ];
        camelcase = pkgs.vimPlugins.camelcasemotion;
        codecompanion = with pkgs.neovimPlugins; [
          codecompanion-nvim
          codecompanion-history-nvim
          mcphub-nvim
        ];
        colorizer = pkgs.vimPlugins.nvim-colorizer-lua;
        conform = pkgs.vimPlugins.conform-nvim;
        comment = with pkgs.vimPlugins; [
          nvim-ts-context-commentstring
          comment-nvim
        ];
        copilot = pkgs.neovimPlugins.copilot-lua;
        dadbod = with pkgs.vimPlugins; [
          vim-dadbod
          vim-dadbod-ui
          vim-dadbod-completion
        ];
        dap = with pkgs.vimPlugins; [
          nvim-dap
          nvim-dap-ui
          nvim-dap-virtual-text
        ];
        dropbar = pkgs.neovimPlugins.dropbar-nvim;
        flash = pkgs.vimPlugins.flash-nvim;
        fzf-lua = pkgs.neovimPlugins.fzf-lua;
        github = pkgs.neovimPlugins.octo-nvim;
        glance = pkgs.vimPlugins.glance-nvim;
        grug-far = pkgs.vimPlugins.grug-far-nvim;
        hydra = pkgs.vimPlugins.hydra-nvim;
        incline = with pkgs.vimPlugins; [
          incline-nvim
          nvim-web-devicons
        ];
        kulala = pkgs.vimPlugins.kulala-nvim;
        latex = pkgs.vimPlugins.vimtex;
        lualine =
          with pkgs.vimPlugins;
          [
            lualine-nvim
          ]
          ++ pkgs.lib.optionals packageDef.categories.copilot [
            copilot-lualine
          ];
        markdown = with pkgs.vimPlugins; [
          render-markdown-nvim
        ];
        mdx = pkgs.neovimPlugins.mdx-nvim;
        minuet = pkgs.neovimPlugins.minuet-ai-nvim;
        move = pkgs.vimPlugins.mini-move;
        multicursor = pkgs.vimPlugins.multicursors-nvim;
        noice = with pkgs.vimPlugins; [
          noice-nvim
          nui-nvim
        ];
        nx = pkgs.neovimPlugins.nx-nvim;
        overseer = pkgs.vimPlugins.overseer-nvim;
        project = pkgs.vimPlugins.project-nvim;
        qmk = pkgs.vimPlugins.qmk-nvim;
        repeat = pkgs.vimPlugins.vim-repeat;
        schemastore = pkgs.vimPlugins.SchemaStore-nvim;
        screenkey = pkgs.neovimPlugins.screenkey-nvim;
        snacks = pkgs.neovimPlugins.snacks-nvim;
        splitjoin = pkgs.vimPlugins.splitjoin-vim;
        surround = pkgs.vimPlugins.nvim-surround;
        testing = with pkgs.neovimPlugins; [
          neotest
          neotest-vitest
          nvim-nio
        ];
        textobjects = with pkgs.vimPlugins; [
          mini-ai
          vim-textobj-user
          vim-textobj-entire
          vim-textobj-line
        ];
        todo-comments = pkgs.vimPlugins.todo-comments-nvim;
        trouble = pkgs.vimPlugins.trouble-nvim;
        typst = pkgs.vimPlugins.typst-preview-nvim;
        ufo = with pkgs.vimPlugins; [
          promise-async
          nvim-ufo
        ];
        vectorcode = pkgs.vimPlugins.vectorcode-nvim;
        which-key = pkgs.vimPlugins.which-key-nvim;
        window-management = pkgs.vimPlugins.smart-splits-nvim;
        zk = pkgs.vimPlugins.zk-nvim;
      };

      # shared libraries to be added to LD_LIBRARY_PATH
      # variable available to nvim runtime
      sharedLibraries = {
        general = with pkgs; [
          # libgit2
        ];
      };

      environmentVariables = {
        test = {
          CATTESTVAR = "It worked!";
        };
      };

      extraWrapperArgs = {
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
        test = [
          ''--set CATTESTVAR2 "It worked again!"''
        ];
      };

      # lists of the functions you would have passed to
      # python.withPackages or lua.withPackages
      # do not forget to set `hosts.python3.enable` in package settings

      # get the path to this python environment
      # in your lua config via
      # vim.g.python3_host_prog
      # or run from nvim terminal via :!<packagename>-python3
      python3.libraries = {
        test = (_: [ ]);
      };
      # populates $LUA_PATH and $LUA_CPATH
      extraLuaPackages = {
        test = [ (_: [ ]) ];
      };

    };

  packageDefinitions = {
    nvim =
      { pkgs, name, ... }:
      {
        # they contain a settings set defined above
        # see :help nixCats.flake.outputs.settings
        settings = {
          suffix-path = false;
          suffix-LD = true;
          wrapRc = "UNWRAP_IT";
          # IMPORTANT:
          # your alias may not conflict with your other packages.
          aliases = [ "vim" ];
          neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.neovim;
        };
        # and a set of categories that you want
        # (and other information to pass to lua)
        categories = {
          general = true;
          git = true;
          lsp = true;
          treesitter = true;

          themer = true;
          colorscheme = "catppuccin";

          abolish = true;
          arrow = true;
          autopairs = true;
          auto-session = true;
          blink = true;
          camelcase = true;
          codecompanion = true;
          codesnap = true;
          colorizer = true;
          conform = true;
          comment = true;
          copilot = true;
          dadbod = true;
          dap = true;
          dashboard = true;
          dropbar = true;
          flash = true;
          fzf-lua = false;
          github = true;
          glance = true;
          grug-far = true;
          hydra = true;
          incline = true;
          kulala = true;
          latex = true;
          lualine = true;
          markdown = true;
          mdx = true;
          minuet = false;
          move = true;
          multicursor = false;
          noice = true;
          nx = false;
          oil = true;
          overseer = true;
          project = false;
          qmk = true;
          repeat = true;
          schemastore = true;
          screenkey = true;
          snacks = true;
          sops = true;
          splitjoin = true;
          surround = true;
          testing = true;
          textobjects = true;
          todo-comments = true;
          trouble = true;
          typst = true;
          ufo = true;
          vectorcode = false;
          which-key = true;
          window-management = true;
          yaml-schema-crds = true;
          zk = true;

          test = true;

          options = {
            noice = {
              cmdline = {
                view = "cmdline";
              };
            };
          };
        };
        extra = { };
      };
  };
  # In this section, the main thing you will need to do is change the default package name
  # to the name of the packageDefinitions entry you wish to use as the default.
  defaultPackageName = "nvim";
in
# see :help nixCats.flake.outputs.exports
forEachSystem (
  system:
  let
    nixCatsBuilder = utils.baseBuilder luaPath {
      inherit
        system
        dependencyOverlays
        extra_pkg_config
        nixpkgs
        ;
    } categoryDefinitions packageDefinitions;
    defaultPackage = nixCatsBuilder defaultPackageName;
    # this is just for using utils such as pkgs.mkShell
    # The one used to build neovim is resolved inside the builder
    # and is passed to our categoryDefinitions and packageDefinitions
    pkgs = import nixpkgs { inherit system; };
  in
  {
    # this will make a package out of each of the packageDefinitions defined above
    # and set the default package to the one passed in here.
    packages = (utils.mkAllWithDefault defaultPackage) // {
      nvim-unwrapped = pkgs.writeShellScriptBin "unwrap-nvim" ''
        exec env UNWRAP_IT=true ${defaultPackage}/bin/nvim "$@"
      '';
    };

    # choose your package for devShell
    # and add whatever else you want in it.
    devShells = {
      default = pkgs.mkShell {
        name = defaultPackageName;
        packages = [ defaultPackage ];
        inputsFrom = [ ];
        shellHook = "";
      };
    };

  }
)
// (
  let
    # we also export a nixos module to allow reconfiguration from configuration.nix
    nixosModule = utils.mkNixosModules {
      moduleNamespace = [ defaultPackageName ];
      inherit
        defaultPackageName
        dependencyOverlays
        luaPath
        categoryDefinitions
        packageDefinitions
        extra_pkg_config
        nixpkgs
        ;
    };
    # and the same for home manager
    homeModule = utils.mkHomeModules {
      moduleNamespace = [ defaultPackageName ];
      inherit
        defaultPackageName
        dependencyOverlays
        luaPath
        categoryDefinitions
        packageDefinitions
        extra_pkg_config
        nixpkgs
        ;
    };
  in
  {

    # these outputs will be NOT wrapped with ${system}

    # this will make an overlay out of each of the packageDefinitions defined above
    # and set the default overlay to the one named here.
    overlays = utils.makeOverlays luaPath {
      # we pass in the things to make a pkgs variable to build nvim with later
      inherit nixpkgs dependencyOverlays extra_pkg_config;
      # and also our categoryDefinitions
    } categoryDefinitions packageDefinitions defaultPackageName;

    nixosModules.default = nixosModule;
    homeModules.default = homeModule;

    inherit utils nixosModule homeModule;
    inherit (utils) templates;
  }
)
