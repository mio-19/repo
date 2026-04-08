{
  config,
  pkgs,
  lib,
  robotnix,
  ...
}:
let
  cfg = config.gos;
  llvm = pkgs.llvmPackages_21;
  originalGrapheneosConfig =
    (robotnix.lib.robotnixSystem (
      { ... }:
      {
        inherit (config)
          flavor
          stateVersion
          device
          ;
        grapheneos.channel = config.grapheneos.channel;
      }
    )).config;

  sourceBuiltClangHostLinuxX86 =
    let
      original = originalGrapheneosConfig.source.dirs."prebuilts/clang/host/linux-x86".src;
      clangBin = lib.getBin llvm.clang-unwrapped;
      clangLib = llvm.clang-unwrapped.lib;
      llvmBin = lib.getBin llvm.llvm;
      llvmLib = llvm.llvm.lib;
      lldBin = lib.getBin llvm.lld;
      clangToolsBin = lib.getBin llvm.clang-tools;

      toolLinks = {
        clang = "${clangBin}/bin/clang";
        "clang++" = "${clangBin}/bin/clang++";
        "clang-21" = "${clangBin}/bin/clang-21";
        "clang-check" = "${clangToolsBin}/bin/clang-check";
        "clang-format" = "${clangToolsBin}/bin/clang-format";
        "clang-scan-deps" = "${clangToolsBin}/bin/clang-scan-deps";
        "clang-tidy" = "${clangToolsBin}/bin/clang-tidy";
        clangd = "${clangToolsBin}/bin/clangd";
        dsymutil = "${llvmBin}/bin/dsymutil";
        "git-clang-format" = "${clangToolsBin}/bin/git-clang-format";
        lld = "${lldBin}/bin/lld";
        "llvm-ar" = "${llvmBin}/bin/llvm-ar";
        "llvm-as" = "${llvmBin}/bin/llvm-as";
        "llvm-cfi-verify" = "${llvmBin}/bin/llvm-cfi-verify";
        "llvm-cov" = "${llvmBin}/bin/llvm-cov";
        "llvm-cxxfilt" = "${llvmBin}/bin/llvm-cxxfilt";
        "llvm-dis" = "${llvmBin}/bin/llvm-dis";
        "llvm-dwarfdump" = "${llvmBin}/bin/llvm-dwarfdump";
        "llvm-dwp" = "${llvmBin}/bin/llvm-dwp";
        "llvm-ifs" = "${llvmBin}/bin/llvm-ifs";
        "llvm-link" = "${llvmBin}/bin/llvm-link";
        "llvm-ml" = "${llvmBin}/bin/llvm-ml";
        "llvm-modextract" = "${llvmBin}/bin/llvm-modextract";
        "llvm-nm" = "${llvmBin}/bin/llvm-nm";
        "llvm-objcopy" = "${llvmBin}/bin/llvm-objcopy";
        "llvm-objdump" = "${llvmBin}/bin/llvm-objdump";
        "llvm-profdata" = "${llvmBin}/bin/llvm-profdata";
        "llvm-rc" = "${llvmBin}/bin/llvm-rc";
        "llvm-readobj" = "${llvmBin}/bin/llvm-readobj";
        "llvm-size" = "${llvmBin}/bin/llvm-size";
        "llvm-strings" = "${llvmBin}/bin/llvm-strings";
        "llvm-symbolizer" = "${llvmBin}/bin/llvm-symbolizer";
        sancov = "${llvmBin}/bin/sancov";
        sanstats = "${llvmBin}/bin/sanstats";
        "scan-build" = "${clangBin}/bin/scan-build";
        "scan-view" = "${clangToolsBin}/bin/scan-view";
      };

      hostLibLinks = {
        "libclang-cpp.so" = "${clangLib}/lib/libclang-cpp.so";
        "libclang.so" = "${clangLib}/lib/libclang.so";
        "libLLVM-21.so" = "${llvmLib}/lib/libLLVM-21.so";
        "libLLVM.so" = "${llvmLib}/lib/libLLVM.so";
        "libLTO.so" = "${llvmLib}/lib/libLTO.so";
        "libRemarks.so" = "${llvmLib}/lib/libRemarks.so";
        "LLVMPolly.so" = "${llvmLib}/lib/LLVMPolly.so";
      };
    in
    pkgs.runCommand "grapheneos-prebuilts-clang-host-linux-x86-source-built" { } ''
      cp --reflink=auto --no-preserve=ownership -r ${original} $out
      chmod -R u+w $out

      for dir in clang-r563880 clang-r563880c; do
        mkdir -p "$out/$dir/bin" "$out/$dir/lib"
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: path: ''
          if [ -e ${path} ]; then
            rm -f "$out/$dir/bin/${name}"
            ln -s ${path} "$out/$dir/bin/${name}"
          fi
        '') toolLinks
      )}

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: path: ''
          if [ -e ${path} ]; then
            rm -f "$out/$dir/lib/${name}"
            ln -s ${path} "$out/$dir/lib/${name}"
          fi
        '') hostLibLinks
      )}
      done

      rm -rf "$out/llvm-binutils-stable"
      mkdir -p "$out/llvm-binutils-stable"
      for tool in llvm-addr2line llvm-ar llvm-as llvm-cov llvm-cxxfilt llvm-dis llvm-dwarfdump llvm-link llvm-modextract llvm-nm llvm-objcopy llvm-objdump llvm-profdata llvm-ranlib llvm-readelf llvm-readobj llvm-size llvm-strings llvm-strip llvm-symbolizer; do
        if [ -e "$out/clang-r563880/bin/$tool" ]; then
          ln -s "../clang-r563880/bin/$tool" "$out/llvm-binutils-stable/$tool"
        fi
      done

      rm -rf "$out/clang-stable/bin" "$out/clang-stable/lib"
      mkdir -p "$out/clang-stable/bin" "$out/clang-stable/lib"
      ln -s ${clangToolsBin}/bin/clang-format "$out/clang-stable/bin/clang-format"
      ln -s ${clangToolsBin}/bin/git-clang-format "$out/clang-stable/bin/git-clang-format"
      ln -s ${clangLib}/lib/libclang.so "$out/clang-stable/lib/libclang.so"
    '';
in
{
  options.gos.useSourceBuiltToolchain = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Replace GrapheneOS's host LLVM toolchain prebuilts with source-built
      LLVM 21 packages from nixpkgs while preserving the Android-target runtime
      payload bundled in AOSP's prebuilt tree.
    '';
  };

  config = lib.mkIf cfg.useSourceBuiltToolchain {
    source.dirs."prebuilts/clang/host/linux-x86" = lib.mkForce {
      src = sourceBuiltClangHostLinuxX86;
    };
  };
}
