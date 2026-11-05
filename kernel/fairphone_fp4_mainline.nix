{
  lib,
  stdenv,
  buildPackages,
  pkgs,
  fetchFromGitHub,
  bc,
  bison,
  flex,
  openssl,
  perl,
  python3,
  dtc,
  kmod,
  rsync,
}:
let
  crossCC = pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc;
  kernelMakeFlags = lib.escapeShellArgs [
    "ARCH=arm64"
    "CROSS_COMPILE=${crossCC.targetPrefix}"
    "HOSTCC=${buildPackages.stdenv.cc}/bin/cc"
    "HOSTCXX=${buildPackages.stdenv.cc}/bin/c++"
    "KBUILD_BUILD_TIMESTAMP=2026-08-26"
    "KBUILD_BUILD_USER=nix"
    "KBUILD_BUILD_HOST=localhost"
    "KBUILD_BUILD_VERSION=1"
  ];
in
stdenv.mkDerivation {
  pname = "fairphone-fp4-mainline-kernel";
  version = "7.2.0-sm6350";

  # Nura's linux-postmarketos-qcom-sm6350 package, maintained by Luca Weiss:
  # https://pkgs.nura.eco/package/main/postmarketos/aarch64/linux-postmarketos-qcom-sm6350
  # Source project: sm6350-mainline/Linux contributors; GPL-2.0-only.
  src = fetchFromGitHub {
    owner = "sm6350-mainline";
    repo = "linux";
    tag = "v7.2.0-sm6350";
    hash = "sha256-pgVa9vgAe/PmXAPUcBQGfCtG+k/dZpcm3UDbH8rOTeg=";
  };

  nativeBuildInputs = [
    bc
    bison
    flex
    perl
    python3
    dtc
    kmod
    rsync
    crossCC
    buildPackages.openssl
  ];
  depsBuildBuild = [ buildPackages.stdenv.cc ];
  buildInputs = [ openssl ];
  enableParallelBuilding = true;
  dontStrip = true;
  dontFixup = true;

  configurePhase = ''
    runHook preConfigure
    make ${kernelMakeFlags} fp4_defconfig
    scripts/kconfig/merge_config.sh -m .config ${./fairphone_fp4_mainline.config}
    make ${kernelMakeFlags} olddefconfig
    for required in ANDROID_BINDER_IPC ANDROID_BINDERFS SECURITY_SELINUX DM_VERITY FS_ENCRYPTION; do
      grep -Fx "CONFIG_$required=y" .config
    done
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    make ${kernelMakeFlags} -j"$NIX_BUILD_CORES" Image.gz qcom/sm7225-fairphone-fp4.dtb modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/dtb"
    mv arch/arm64/boot/Image.gz "$out/Image.gz"
    mv arch/arm64/boot/dts/qcom/sm7225-fairphone-fp4.dtb "$out/dtb/"
    cp .config "$out/kernel.config"
    make ${kernelMakeFlags} INSTALL_MOD_PATH="$out" INSTALL_MOD_STRIP=1 modules_install
    make ${kernelMakeFlags} INSTALL_HDR_PATH="$out/headers" headers_install
    rm -f "$out"/lib/modules/*/build "$out"/lib/modules/*/source
    runHook postInstall
  '';

  meta = {
    description = "Experimental Android-configured mainline kernel for Fairphone 4";
    homepage = "https://github.com/sm6350-mainline/linux";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
