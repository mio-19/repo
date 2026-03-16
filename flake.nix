{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-25.05";
    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
    android-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
    #  --option extra-substituters https://robotnix.cachix.org --option extra-trusted-public-keys robotnix.cachix.org-1:+y88eX6KTvkJyernp1knbpttlaLTboVp4vq/b24BIv0=
    #robotnix.url = "git+https://github.com/nix-community/robotnix.git?shallow=1";
    #robotnix.url = "github:nix-community/robotnix/grapheneos_2026-02-14";
    robotnix.url = "github:mio-19/robotnix";
    robotnix.inputs.nixpkgs.follows = "nixpkgs-stable";
    robotnix.inputs.androidPkgs.follows = "android-nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    # https://github.com/xddxdd/nix-kernelsu-builder
    nix-kernelsu-builder.url = "github:xddxdd/nix-kernelsu-builder/cc0fce340e330ad07331692b7c3673d9974be377";
    nix-kernelsu-builder.inputs.flake-parts.follows = "flake-parts";
    nix-kernelsu-builder.inputs.nixpkgs.follows = "nixpkgs";
    # --option extra-substituters https://nixos-apple-silicon.cachix.org --option extra-trusted-public-keys nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20=
    nixos-apple-silicon = {
      #url = "github:nix-community/nixos-apple-silicon";
      # merged with https://github.com/nix-community/nixos-apple-silicon/pull/353
      #url = "github:mio-19/nixos-apple-silicon";
      # https://github.com/nix-community/nixos-apple-silicon/issues/384
      url = "github:mio-19/nixos-apple-silicon/mio-release-2025-08-23";
      #inputs.nixpkgs.follows = "nixpkgs"; # needs to comment out this to use binary cache
    };
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };
    openwrt-imagebuilder = {
      url = "github:astro/nix-openwrt-imagebuilder";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    gradle2nix = {
      url = "github:tadfisher/gradle2nix/v2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      imports = [
        inputs.nix-kernelsu-builder.flakeModules.default
        ./openwrt.nix
        ./robotnix.nix
        ./app
      ];
      perSystem =
        args@{ pkgs, system, ... }:
        {
          # https://github.com/nix-community/nixos-apple-silicon/pull/353
          packages.zfs-installer =
            (nixpkgs.lib.nixosSystem {
              inherit system;
              pkgs = import nixpkgs {
                crossSystem.system = "aarch64-linux";
                localSystem.system = system;
                overlays = [ inputs.nixos-apple-silicon.overlays.default ];
              };
              modules = [
                inputs.nixos-apple-silicon.outputs.nixosModules.apple-silicon-installer
                {
                  hardware.asahi.pkgsSystem = system;
                  nixpkgs.hostPlatform.system = "aarch64-linux";
                  nixpkgs.buildPlatform.system = system;
                }
                (
                  { pkgs, ... }:
                  {
                    boot.supportedFilesystems.zfs = true;
                    networking.hostId = "AAAAAAAA";
                    environment.systemPackages = with pkgs; [
                      git
                      rsync
                    ];
                  }
                )
              ];
            }).config.system.build.isoImage;
        };
    };
  nixConfig = {
    extra-substituters = [
      # https://garnix.io/docs/caching # garnix sometimes often 504 Gateway Time-out. to avoid waiting on this garnix, supply `--offline` to nix commands.
      "https://cache.garnix.io"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };
}
