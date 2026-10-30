{
  self,
  inputs,
  ...
}:
let
  inherit (inputs) nixpkgs nix-github-actions;
in
{
  imports = [ ./kernel/kernels.nix ];
  flake = {
    githubActions = nix-github-actions.lib.mkGithubMatrix {
      checks.x86_64-linux =
        with nixpkgs.lib;
        (mapAttrs' (name: cfg: nameValuePair "${name}-ota" cfg.ota) losNoCcache)
        // (mapAttrs' (name: cfg: nameValuePair "${name}-img" cfg.img) losNoCcache);
    };
    inherit (self.legacyPackages.x86_64-linux)
      los
      gos
      losNoCcache
      gosNoCcache
      ;
  };
  perSystem =
    { inputsPatched, pkgsPatched, ... }:
    let
      inherit (inputsPatched) nixpkgs robotnix;
      mkGos =
        { ccache }:
        let
          common =
            f:
            { ... }:
            {
              _module.args.pkgs-unfree = pkgsPatched;
              _module.args.robotnix = robotnix;
              _module.args.self = self;
              imports = [
                f
                (import ./gos/avb-custom-key.nix {
                  inherit (nixpkgs) lib;
                  inherit robotnix;
                })
              ];
              ccache.enable = ccache;
            };
        in
        # https://github.com/MatthewCroughan/nixcfg/blob/afab322e6da20cc038d8577dd4a365673702d183/flake.nix#L57
        nixpkgs.lib.mapAttrs (n: v: robotnix.lib.robotnixSystem v) {
          akita = common ./gos/devices/akita.nix;
          husky = common ./gos/devices/husky.nix;
          mustang = common ./gos/devices/mustang.nix;
          tangorpro = common ./gos/devices/tangorpro.nix;
          cheetah = common ./gos/devices/cheetah.nix;
          caiman = common ./gos/devices/caiman.nix;
          komodo = common ./gos/devices/komodo.nix;
        };
      mkLos =
        { ccache }:
        let
          common =
            f:
            { ... }:
            {
              _module.args.pkgs-unfree = pkgsPatched;
              _module.args.robotnix = robotnix;
              _module.args.self = self;
              _module.args.inputs = inputsPatched;
              imports = [ f ];
              ccache.enable = ccache;
            };
        in
        # https://github.com/MatthewCroughan/nixcfg/blob/afab322e6da20cc038d8577dd4a365673702d183/flake.nix#L57
        nixpkgs.lib.mapAttrs (n: v: robotnix.lib.robotnixSystem v) {
          FP4 = common ./los/devices/FP4.nix;
          FP4_mainline = common ./los/devices/FP4-mainline.nix;
          gta4xlwifi = common ./los/devices/gta4xlwifi.nix;
          enchilada = common ./los/devices/enchilada.nix;
          enchilada_derpfest16 = common ./los/devices/enchilada-derpfest16.nix;
          enchilada_mainline = common ./los/devices/enchilada-mainline.nix;
          nx_tab = common ./los/devices/nx_tab.nix;
          utm = common ./los/devices/utm.nix;
          akita = common ./los/devices/akita.nix;
          dm3q-kenzie = common ./los/devices/dm3q-kenzie.nix;
          dm3q_cola2261 = common ./los/devices/dm3q-cola2261.nix;
          gts9wifi = common ./los/devices/gts9wifi.nix;
          gts8wifi = common ./los/devices/gts8wifi.nix;
          gts8wifi_24_0 = common ./los/devices/gts8wifi_24_0.nix;
          gts8 = common ./los/devices/gts8.nix;
          gts8_24_0 = common ./los/devices/gts8_24_0.nix;
          gts7lwifi = common ./los/devices/gts7lwifi.nix;
          gts7l = common ./los/devices/gts7l.nix;
          hibreak_pro = common ./los/devices/hibreak_pro.nix;
        };
      pkgs = pkgsPatched;
    in
    {
      legacyPackages = {
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
      packages.grapheneos-husky-kernel = pkgs.callPackage ./gos/kernels/shusky.nix { };
      packages.grapheneos-mustang-kernel = pkgs.callPackage ./gos/kernels/mustang.nix { };
      packages.grapheneos-tangorpro-kernel = pkgs.callPackage ./gos/kernels/tangorpro.nix { };
      packages.grapheneos-caiman-kernel = pkgs.callPackage ./gos/kernels/caimito.nix {
        enableKSU = false;
        enableLindroid = false;
        enableDroidspaces = false;
      };
      # followings are for debugging:
      packages.grapheneos-husky-key-script = self.gosNoCcache.husky.generateKeysScript;
      packages.grapheneos-husky-factory-img = self.gosNoCcache.husky.factoryImg;
      packages.grapheneos-tangorpro-key-script = self.gosNoCcache.tangorpro.generateKeysScript;
      packages.grapheneos-tangorpro-factory-img = self.gosNoCcache.tangorpro.factoryImg;
      packages.los-gts7lwifi-ota = self.losNoCcache.gts7lwifi.ota;
      packages.los-gts7l-ota = self.losNoCcache.gts7l.ota;
      packages.los-enchilada-img = self.losNoCcache.enchilada.img;
      packages.los-utm-img = self.losNoCcache.utm.img;
      packages.lineageos-fp4-img = self.losNoCcache.FP4.img;
      packages.lineageos-fp4-ota = self.losNoCcache.FP4.ota;
      packages.lineageos-fp4-mainline-img = self.losNoCcache.FP4_mainline.img;
      packages.lineageos-fp4-mainline-ota = self.losNoCcache.FP4_mainline.ota;
      packages.fairphone-fp4-mainline-kernel = pkgs.callPackage ./kernel/fairphone_fp4_mainline.nix { };
      packages.grapheneos-husky-srcs = pkgs.srcOnly self.gos.husky.config.build.android;
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
      packages.ksuNext = pkgs.callPackage ./kernel/ksu/ksuNext.nix { };
    };
}
