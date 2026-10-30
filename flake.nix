{
  description = "charlotte's nix config";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs";
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
