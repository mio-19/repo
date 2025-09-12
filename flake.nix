# see log: adb logcat | grep lindroid
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nix-github-actions.url = "github:nix-community/nix-github-actions";
  inputs.nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
  #  --option extra-substituters https://robotnix.cachix.org --option extra-trusted-public-keys robotnix.cachix.org-1:+y88eX6KTvkJyernp1knbpttlaLTboVp4vq/b24BIv0=
  inputs.robotnix.url = "github:nix-community/robotnix";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.nix-kernelsu-builder.url = "github:xddxdd/nix-kernelsu-builder";

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
              (mapAttrs' (name: cfg: nameValuePair "${name}-ota" cfg.ota) self.robotnixConfigurationsNoCcache)
              // (mapAttrs' (name: cfg: nameValuePair "${name}-img" cfg.img) self.robotnixConfigurationsNoCcache);
          };
          robotnixConfigurations = mkRobotnixConfigurations true;
          robotnixConfigurationsNoCcache = mkRobotnixConfigurations false;
        };
      systems = [ "x86_64-linux" ];
      perSystem =
        { pkgs, ... }:
        {
          kernelsu = {
            oriole = {
              anyKernelVariant = "kernelsu";
              clangVersion = "latest";

              kernelSU.variant = "next";
              kernelImageName = "Image";
              kernelSrc = pkgs.fetchgit {
                url = "https://android.googlesource.com/kernel/common";
                rev = "8b4d6dfa520d2a494ed95bd70f9f0ad06b83fc27";
                ref = "android-gs-raviole-6.1-android15-qpr2";
                sha256 = "1a7wic2f4r9y40pia3z86rgixszcags06pmld8anic4i8k9nc40y";
              };

            };
          };
        };
    };
}
