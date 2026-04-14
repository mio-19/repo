{
  callPackage,
  fetchFromGitHub,
  jdk25_headless,
  writableTmpDirAsHomeHook,
  srcOnly,
  lib,
  stdenv,
  squish-find-the-brains,
  pkgs,
}:
let
  sbt_nixpkgs = callPackage ./nixpkgs.nix { };
  coursierCache = squish-find-the-brains.lib.mkCoursierCache {
    inherit pkgs;
    lockfilePath = ./deps.lock.json;
  };

  sbtSetup = squish-find-the-brains.lib.mkSbtSetup {
    inherit pkgs coursierCache;
  };
in
sbt_nixpkgs.overrideAttrs (
  finalAttrs: prevAttrs: {
    bootstrapSbt = sbt_nixpkgs;
    jdk = jdk25_headless;
    version = "1.12.9";
    src = null;
    # https://discourse.nixos.org/t/how-to-create-package-with-multiple-sources/9308/2
    srcs = [
      (fetchFromGitHub {
        name = "sbt";
        owner = "sbt";
        repo = "sbt";
        tag = "v${finalAttrs.version}";
        hash = finalAttrs.sbt_hash;
      })
      (fetchFromGitHub {
        name = "io";
        owner = "sbt";
        repo = "io";
        tag = "v${finalAttrs.io_version}";
        hash = finalAttrs.io_hash;
      })
      (fetchFromGitHub {
        name = "zinc";
        owner = "sbt";
        repo = "zinc";
        tag = "v${finalAttrs.zinc_version}";
        hash = finalAttrs.zinc_hash;
      })
    ];
    sourceRoot = ".";
    postPatch = "";
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ sbtSetup.nativeBuildInputs;
    io_version = "1.10.5";
    zinc_version = "1.12.0";
    sbt_hash = "sha256-PgC5HYAhUnNpkHqmfDAIg2Mtbcz3oJPlWqFsUUhyREY=";
    io_hash = "sha256-dgvMYYJhgYp9YbJ3C3msoxN08yxNvL1wCDIeV9pIcKI=";
    zinc_hash = "sha256-SlmoL1y3qJm3ntM8rIAZQFuIEcBfqieo8dWd8x0+7/U=";
    # https://www.scala-sbt.org/1.x/docs/Command-Line-Reference.html
    preBuild = lib.optionalString stdenv.isDarwin ''
      export SBT_OPTS="-Dsbt.global.base=$HOME/.sbt/1.0"
    '';
    #inherit (sbtSetup) JAVA_HOME;
    # https://github.com/sbt/sbt/blob/develop/.github/workflows/nightly.yml
    buildPhase = ''
      runHook preBuild

      cd sbt
      sh sbt-allsources.sh "+lowerUtils/publish; {zinc}/publish; upperModules/publish; bundledLauncherProj/publish"
      exit 1

      runHook postBuild
    '';
    passthru.srcOnly = srcOnly finalAttrs.finalPackage;
  }
)
