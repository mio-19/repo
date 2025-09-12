# see log: adb logcat | grep lindroid
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
    android-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
    #  --option extra-substituters https://robotnix.cachix.org --option extra-trusted-public-keys robotnix.cachix.org-1:+y88eX6KTvkJyernp1knbpttlaLTboVp4vq/b24BIv0=
    robotnix.url = "github:nix-community/robotnix";
    robotnix.inputs.nixpkgs.follows = "nixpkgs";
    robotnix.inputs.androidPkgs.follows = "android-nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    # https://github.com/xddxdd/nix-kernelsu-builder
    nix-kernelsu-builder.url = "github:xddxdd/nix-kernelsu-builder";
    nix-kernelsu-builder.inputs.flake-parts.follows = "flake-parts";
    nix-kernelsu-builder.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      robotnix,
      nix-github-actions,
      nixpkgs,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.nix-kernelsu-builder.flakeModules.default
      ];
      flake =
        let
          # https://github.com/MatthewCroughan/nixcfg/blob/afab322e6da20cc038d8577dd4a365673702d183/flake.nix#L57
          mkRobotnixConfigurations =
            ccache:
            let
              common = {
                ccache.enable = ccache;
              };
            in
            nixpkgs.lib.mapAttrs (n: v: robotnix.lib.robotnixSystem v) {
              gta4xlwifi = args@{ config, pkgs, ... }: common // ((import ./gta4xlwifi.nix) args);
              enchilada = args@{ config, pkgs, ... }: common // ((import ./enchilada.nix) args);
              nx_tab = args@{ config, pkgs, ... }: common // ((import ./nx_tab.nix) args);
              oriole = args@{ config, pkgs, ... }: common // ((import ./oriole.nix) args);
            };
        in
        {
          githubActions = nix-github-actions.lib.mkGithubMatrix {
            checks.x86_64-linux =
              with nixpkgs.lib;
              (mapAttrs' (name: cfg: nameValuePair "${name}-ota" cfg.ota) self.androidNoCcache)
              // (mapAttrs' (name: cfg: nameValuePair "${name}-img" cfg.img) self.androidNoCcache);
          };
          android = mkRobotnixConfigurations true;
          androidNoCcache = mkRobotnixConfigurations false;
        };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      perSystem =
        { pkgs, ... }:
        let
          sources = (import ./_sources/generated.nix) {
            inherit (pkgs)
              fetchurl
              fetchgit
              fetchFromGitHub
              dockerTools
              ;
          };
        in
        {
          kernelsu = {
            oriole = {
              anyKernelVariant = "kernelsu";
              clangVersion = "latest";
              kernelDefconfigs = [
                "gki_defconfig"
              ];
              kernelSU.variant = "next";
              kernelImageName = "Image";
              kernelSrc = sources.oriole-kernel.src;
              oemBootImg = pkgs.fetchurl {
                url = "https://mirrorbits.lineageos.org/full/oriole/20250908/boot.img";
                sha256 = "1bivg0sn1zs8plcsncv1jpcp81n15xw1hyhq07pfz11wnp8y50hg";
              };
            };
            enchilada = {
              anyKernelVariant = "kernelsu";
              clangVersion = null;
              kernelDefconfigs = [
                "enchilada_defconfig"
              ];
              kernelSU.variant = "next";
              kernelImageName = "Image";
              kernelSrc = sources.enchilada-kernel.src;
              kernelPatches = [ ./9596554cfbdab57682a430c15ca64c691d404152.patch ];
              oemBootImg = pkgs.fetchurl {
                url = "https://mirrorbits.lineageos.org/full/enchilada/20250910/boot.img";
                sha256 = "0d2cxz3jhi54qvlqmfghga621851njjxsldr9w8n1ni4g6g2nslp";
              };
            };
          };
        };
    };
}
