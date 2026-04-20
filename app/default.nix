{ inputs, ... }:
{
  perSystem =
    {
      system,
      gradle2nixV1Patched,
      gradle2nixPatched,
      pkgsPatched,
      squish-find-the-brains,
      inputsPatched,
      ...
    }:
    let
      pkgs = pkgsPatched;
      inherit (pkgs) lib;
      sources = (import ../_sources/generated.nix) {
        inherit (pkgs)
          fetchurl
          fetchgit
          fetchFromGitHub
          dockerTools
          ;
      };
      mvn2nixMaven = pkgs.callPackage "${inputs.mvn2nix}/maven.nix" { };
      gradle2nixScope = pkgs.callPackage "${gradle2nixPatched}/nix" { };
      sourceBuiltNdkHelper = pkgs.callPackage ./source-built-ndk.nix {
        robotnix = inputsPatched.robotnix;
      };
      helpers = {
        buildMavenRepositoryFromLockFile-bare = mvn2nixMaven.buildMavenRepositoryFromLockFile;
        androidSdkBuilder =
          selector:
          inputs.android-nixpkgs.sdk.${system} (
            s:
            let
              selected = selector s;
            in
            map (
              pkg:
              if lib.isDerivation pkg && lib.hasPrefix "ndk-" (pkg.pname or "") then
                sourceBuiltNdkHelper.mkSourceBuiltNdk pkg
              else
                pkg
            ) selected
          );
        inherit (gradle2nixScope) gradleSetupHook;
        gradle2nixV1Builders = gradle2nixV1Patched.builders.${system};
        inherit
          sources
          pkgsPatched
          libs
          squish-find-the-brains
          ;
        apktool-src = sources.morphe_apktool.src;
        multidexlib2-src = sources.morphe_multidexlib2.src;
      };
      apkScope = lib.makeScope pkgs.newScope (_: byName // helpers // libs);
      apk = lib.filesystem.packagesFromDirectoryRecursive {
        inherit (apkScope) callPackage newScope;
        directory = ./apks;
      };
      libBase = lib.makeScope pkgs.newScope (_: helpers // byName);
      libs = lib.filesystem.packagesFromDirectoryRecursive {
        inherit (libBase)
          callPackage
          newScope
          ;
        directory = ../libs;
      };
      byNameBase = lib.makeScope libBase.newScope (
        _:
        {
          inherit apk;
        }
        // libs
      );
      byName = lib.filesystem.packagesFromDirectoryRecursive {
        inherit (byNameBase)
          callPackage
          newScope
          ;
        directory = ./by-name;
      };
    in
    rec {
      _module.args.libs = libs;
      packages = lib.filterAttrs (_: lib.isDerivation) legacyPackages;
      legacyPackages =
        byName // libs // lib.mapAttrs' (name: value: lib.nameValuePair ("apk_" + name) value) apk;
    };
}
