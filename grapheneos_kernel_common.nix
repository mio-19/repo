{
  bash,
  bc,
  bison,
  buildFHSEnv,
  bashInteractive,
  cpio,
  file,
  findutils,
  flex,
  gawk,
  glibc,
  gnugrep,
  gnumake,
  gnused,
  hostname,
  lib,
  openssl,
  patch,
  perl,
  python3,
  rsync,
  stdenvNoCC,
  fetchgit,
  which,
  zlib,
}:
{
  pname,
  version ? src.tag,
  src ? fetchgit {
    url = "https://gitlab.com/grapheneos/kernel_pixel.git";
    tag = "2026030700";
    fetchSubmodules = true;
    deepClone = false;
    #leaveDotGit = true; # seems like something wants .git # needed after 20260305
    sparseCheckout = [ ];
    hash = "sha256-WuQLB1/PzO7j8WS7L+iaLQeoExuOsP3K21ws0rgilxQ=";
  },
  buildScript,
  distDir,
  installSubdir ? "grapheneos",
  enableKSU,
  ksuMakefilePreamble ? ''
    echo "srctree := $(pwd)/aosp"
    echo "src := KernelSU/kernel"
  '',
  buildCommand ? null,
  extraBuildCommands ? "",
}:
let
  kernelSUSrc = import ./kernelSU105.nix { inherit fetchgit; };
  kernelBuildEnv = buildFHSEnv {
    name = "${pname}-build-env";
    targetPkgs =
      p: with p; [
        bash
        bc
        bison
        cpio
        file
        findutils
        flex
        gawk
        glibc.dev
        stdenv.cc.cc
        git
        gnugrep
        gnumake
        gnused
        hostname
        openssl
        openssl.dev
        patch
        perl
        python3
        rsync
        which
        zlib
      ];
    runScript = "${bashInteractive}/bin/bash";
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version src;
  dontConfigure = true;
  dontFixup = true;

  buildPhase = ''
    set -euo pipefail
    runHook preBuild
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"

    ${kernelBuildEnv}/bin/${pname}-build-env -c '
      set -euo pipefail
      apply_patch() {
        local patch_file="$1"
        echo "Applying patch: $patch_file"
        patch -p1 --batch --forward --no-backup-if-mismatch < "$patch_file"
      }

      ${extraBuildCommands}
      ${lib.optionalString enableKSU ''
        # KernelSU v1.0.5 style tree injection shared across GrapheneOS kernels.
        rm -rf aosp/KernelSU
        cp -r ${kernelSUSrc} aosp/KernelSU
        chmod -R u+w aosp/KernelSU
        ln -sfn ../KernelSU/kernel aosp/drivers/kernelsu
        printf "\nobj-\$(CONFIG_KSU) += kernelsu/\n" >> aosp/drivers/Makefile
        sed -i "/endmenu/i\\source \"drivers/kernelsu/Kconfig\"" aosp/drivers/Kconfig

        cp aosp/KernelSU/kernel/Makefile aosp/KernelSU/kernel/Makefile.orig
        {
          ${ksuMakefilePreamble}
          cat aosp/KernelSU/kernel/Makefile.orig
        } > aosp/KernelSU/kernel/Makefile
      ''}
      ${
        if buildCommand != null then
          buildCommand
        else
          ''
            export KLEAF_REPO_MANIFEST=aosp_manifest.xml
            ./${buildScript} --lto=full
          ''
      }
    '
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/${installSubdir}"
    cp -r out/${distDir}/dist/. "$out/${installSubdir}/"
    runHook postInstall
  '';
}
