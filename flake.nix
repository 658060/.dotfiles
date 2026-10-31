{
  description = "charlotte's nix config";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    nvf.url = "github:notashelf/nvf";
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:danth/stylix";
    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    inherit (nixpkgs) lib;
    pkgs = nixpkgs.legacyPackages.${system};

    overlays = [
      (final: prev: {
        customPkgs = import ./modules/packages {pkgs = prev;};
        waybar = prev.waybar.overrideAttrs (old: {
          patches = (old.patches or []) ++ [ ./modules/home/waybar/hyprland-lua-dispatch.patch ];
        });
        # discord retired the modal api that 1.6.5's ScreenSharePicker uses, so
        # after the portal picker the settings modal crashes and the share is
        # granted an empty stream ("Invalid capture constraints"). 1.6.6+
        # migrated (Vesktop 04e9027). hashes from nixpkgs#553927; drop this
        # overlay once that lands in the pinned nixpkgs.
        vesktop = prev.vesktop.overrideAttrs (old: rec {
          version = "1.6.7";
          src = prev.fetchFromGitHub {
            owner = "Vencord";
            repo = "Vesktop";
            rev = "v${version}";
            hash = "sha256-Y74FIqcY26Dizz+DoY+r8caOfX+4/VmiEbmhcOpMHqE=";
          };
          pnpmDeps = old.pnpmDeps.overrideAttrs (o: {
            pname = "vesktop-pnpm-deps";
            inherit version src;
            outputHash = "sha256-AK+ZbylpG7iKWKsIA0nfFfZYP7HaTCTSeDbNUFx/iY4=";
          });
        });
        # 1.4.1 still tears down screencast streams when dma-buf alloc fails
        # and the session renegotiates to shm, which breaks vesktop/discord
        # screenshare (xdph #418; fixed by #424 and #425, merged but
        # unreleased). pin master until 1.4.2, then drop this.
        xdg-desktop-portal-hyprland = prev.xdg-desktop-portal-hyprland.overrideAttrs (old: {
          version = "1.4.1-unstable-2026-08-17";
          src = prev.fetchFromGitHub {
            owner = "hyprwm";
            repo = "xdg-desktop-portal-hyprland";
            rev = "59d429bf45aed4e2209043c0c36565ad8e2859a5";
            hash = "sha256-frEFLVRj8xXvBBDs44IRiqHo6R2PxsRpluygL7abjjI=";
          };
        });
      })
    ];

    # Auto-discover every host directory under ./hosts and build one
    # nixosConfiguration per hostname. Each host's variables.nix names its own
    # `profile` (driver bundle) and `user` (identity), so flake.nix is never
    # edited per-machine — adding a device is just dropping in hosts/<name>/.
    # Build with `--hostname $(hostname)` (see the fr/fu aliases).
    hosts = builtins.attrNames (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
    );

    # The driver bundles a host may name; read straight off ./profiles so this
    # stays correct as profiles come and go (same auto-discovery as hosts).
    validProfiles = builtins.attrNames (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./profiles)
    );

    mkHost = host: let
      vars = import ./hosts/${host}/variables.nix;
      # profile is read here, before the module system runs, to pick which
      # profile to import — so it can't go through the typed variables schema.
      # Guard it explicitly instead: a bad profile names a clear error, not a
      # bare "path ./profiles/<typo> does not exist".
      profile =
        vars.profile
        or (throw "host '${host}': hosts/${host}/variables.nix must set `profile`.");
    in
      assert lib.assertMsg (builtins.elem profile validProfiles)
      "host '${host}': profile '${profile}' is not one of ${toString validProfiles} (a directory under ./profiles).";
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs host profile;
            username = vars.user;
          };
          modules = [
            ./profiles/${profile}
            {nixpkgs.overlays = overlays;}
          ];
        };
  in {
    nixosConfigurations = lib.genAttrs hosts mkHost;

    # dev tooling: a self-installing commit-msg hook enforcing conventional
    # commits. Activated by `.envrc` (`use flake`) via direnv.
    # one `direnv allow` per clone. cocogitto also renders CHANGELOG.md.
    checks.${system}.pre-commit = inputs.git-hooks.lib.${system}.run {
      src = ./.;
      hooks.cog = {
        enable = true;
        name = "cocogitto conventional-commit check";
        entry = "${pkgs.cocogitto}/bin/cog verify --file";
        language = "system";
        stages = ["commit-msg"];
        pass_filenames = true;
      };
    };

    devShells.${system}.default = pkgs.mkShell {
      inherit (self.checks.${system}.pre-commit) shellHook;
      buildInputs =
        self.checks.${system}.pre-commit.enabledPackages
        ++ [pkgs.cocogitto];
    };
  };
}
