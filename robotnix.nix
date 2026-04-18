{
  self,
  inputsPatched,
  pkgsPatched,
  ...
}:
let
  inherit (inputsPatched) nixpkgs robotnix nix-github-actions;
  mkGos =
    { ccache }:
    let
      common =
        f:
        args@{ pkgs, ... }:
        {
          _module.args.pkgs-unfree = pkgsPatched;
          _module.args.robotnix = robotnix;
          _module.args.self = self;
          imports = [ f ];
          ccache.enable = ccache;
        };
    in
    # https://github.com/MatthewCroughan/nixcfg/blob/afab322e6da20cc038d8577dd4a365673702d183/flake.nix#L57
    nixpkgs.lib.mapAttrs (n: v: robotnix.lib.robotnixSystem v) {
      akita = common ./gos_akita.nix;
      husky = common ./gos_husky.nix;
      mustang = common ./gos_mustang.nix;
      tangorpro = common ./gos_tangorpro.nix;
      cheetah = common ./gos_cheetah.nix;
      caiman = common ./gos_caiman.nix;
    };
  mkLos =
    { ccache }:
    let
      common =
        f:
        args@{ pkgs, ... }:
        {
          _module.args.pkgs-unfree = pkgsPatched;
          _module.args.robotnix = robotnix;
          _module.args.self = self;
          imports = [ f ];
          ccache.enable = ccache;
        };
    in
    # https://github.com/MatthewCroughan/nixcfg/blob/afab322e6da20cc038d8577dd4a365673702d183/flake.nix#L57
    nixpkgs.lib.mapAttrs (n: v: robotnix.lib.robotnixSystem v) {
      gta4xlwifi = common ./gta4xlwifi.nix;
      enchilada = common ./enchilada.nix;
      enchilada_derpfest16 = common ./enchilada-derpfest16.nix;
      enchilada_mainline = common ./enchilada-mainline.nix;
      nx_tab = common ./nx_tab.nix;
      utm = common ./utm.nix;
      akita = common ./akita.nix;
      dm3q-kenzie = common ./dm3q-kenzie.nix;
      dm3q_cola2261 = common ./dm3q-cola2261.nix;
      gts9wifi = common ./gts9wifi.nix;
      gts7lwifi = common ./gts7lwifi.nix;
      gts7l = common ./gts7l.nix;
    };
in
{
  imports = [ ./kernels.nix ];
  flake = {
    githubActions = nix-github-actions.lib.mkGithubMatrix {
      checks.x86_64-linux =
        with nixpkgs.lib;
        (mapAttrs' (name: cfg: nameValuePair "${name}-ota" cfg.ota) losNoCcache)
        // (mapAttrs' (name: cfg: nameValuePair "${name}-img" cfg.img) losNoCcache);
    };
    los = mkLos {
      ccache = true;
    };
    gos = mkGos {
      ccache = true;
    };
    gosNoCcache = mkGos {
      ccache = false;
    };
    losNoCcache = mkLos {
      ccache = false;
    };
  };
  perSystem =
    args@{ pkgs, ... }:
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
      packages.grapheneos-husky-kernel = pkgs.callPackage ./gos_kernel_shusky.nix { };
      packages.grapheneos-mustang-kernel = pkgs.callPackage ./gos_mustang_kernel.nix { };
      packages.grapheneos-tangorpro-kernel = pkgs.callPackage ./gos_tangorpro_kernel.nix { };
      # followings are for garnix:
      packages.grapheneos-husky-key-script = self.gosNoCcache.husky.generateKeysScript;
      packages.grapheneos-husky-factory-img = self.gosNoCcache.husky.factoryImg;
      packages.grapheneos-tangorpro-key-script = self.gosNoCcache.tangorpro.generateKeysScript;
      packages.grapheneos-tangorpro-factory-img = self.gosNoCcache.tangorpro.factoryImg;
      packages.los-gts7lwifi-ota = self.losNoCcache.gts7lwifi.ota;
      packages.los-gts7l-ota = self.losNoCcache.gts7l.ota;
      packages.los-enchilada-img = self.losNoCcache.enchilada.img;
      packages.los-utm-img = self.losNoCcache.utm.img;
      /*
        packages.grapheneos-husky-srcs = self.gos.husky.config.build.android.overrideAttrs (old: {
          buildPhase = "";
          installPhase = ''
            mkdir $out
            cp -r . $out/
          '';
        });
      */
      # followings are for debug:
      packages.ksuNext = pkgs.callPackage ./ksuNext.nix { };
    };
}
