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
            nixpkgs.lib.mapAttrs (n: v: robotnix.lib.robotnixSystem v) {
              gta4xlwifi = import ./gta4xlwifi.nix;
              enchilada = import ./enchilada.nix;
              nx_tab = import ./nx_tab.nix;
              oriole = import ./oriole.nix;
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
          };
        };
    };
}
