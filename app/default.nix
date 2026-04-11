{ inputs, ... }:
{
  perSystem =
    {
      lib,
      system,
      gradle2nixV1Patched,
      gradle2nixPatched,
      pkgsPatched,
      ...
    }:
    let
      pkgs = pkgsPatched;
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
      helpers = {
        inherit (mvn2nixMaven) buildMavenRepositoryFromLockFile;
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
        gradle2nixBuilders = {
          inherit (gradle2nixScope) buildGradlePackage buildMavenRepo;
        };
        gradle2nixV1Builders = gradle2nixV1Patched.builders.${system};
        inherit
          sources
          pkgsPatched
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
        directory = ./lib;
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
