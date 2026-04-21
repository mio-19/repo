{
  lib,
  stdenv,
  pkgs,
  robotnix,
  androidSdkBuilder,
}:
let
  aospLlvmBase = {
    version = "21.0.0";
    revision = "386af4a5c64ab75eaee2448dc38f2e34a40bfed0";
    hash = "sha256-30ZqBJ8zFWnGLFVsbI+hVqg2j4VS+pc3MTFbgpmz2ZY=";
  };

  # Standard Linux environment for building AOSP LLVM
  sourceBuiltLlvmFhs = (
    pkgs.buildFHSEnv {
      name = "aosp-llvm-fhs";
      targetPkgs =
        pkgs: with pkgs; [
          cmake
          ninja
          python3
          perl
          zstd
          libxml2
          libedit
          ncurses
          gcc13
          glibc
          glibc.dev
          linuxHeaders
          git
        ];
      runScript = "bash";
    }
  );

  # Build the host toolchain (Clang + LLD) ONLY in a single Pass
  # To avoid OOM and complex runtime issues, we build only what's needed for the NDK toolchain
  sourceBuiltLlvmDrv = stdenv.mkDerivation (finalAttrs: {
    pname = "aosp-llvm";
    version = "r563880";

    src = pkgs.fetchgit {
      url = "https://android.googlesource.com/toolchain/llvm-project";
      rev = "5e96669f06077099aa41290cdb4c5e6fa0f59349"; # mirror-goog-llvm-r563880-release
      hash = "sha256-Efdy0nIa7h9ytmByCiBDju//SBe08lmo7NTwfdTUqG8=";
    };

    nativeBuildInputs = [ sourceBuiltLlvmFhs ];

    buildPhase = ''
      export SRC_DIR=$(pwd)
      aosp-llvm-fhs -c "
        set -e
        mkdir -p build
        cd build
        cmake ../llvm \
          -GNinja \
          -DCMAKE_C_COMPILER=gcc \
          -DCMAKE_CXX_COMPILER=g++ \
          -DCMAKE_C_FLAGS='-Wno-error=dangling-reference' \
          -DCMAKE_CXX_FLAGS='-Wno-error=dangling-reference' \
          -DLLVM_ENABLE_PROJECTS='clang;lld' \
          -DCMAKE_BUILD_TYPE=Release \
          -DLLVM_TARGETS_TO_BUILD='AArch64;ARM;X86' \
          -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON \
          -DLLVM_ENABLE_ZSTD=ON \
          -DCMAKE_INSTALL_PREFIX=$out \
          -DLLVM_PARALLEL_LINK_JOBS=1 \
          -DLLVM_BUILD_LLVM_DYLIB=ON \
          -DLLVM_LINK_LLVM_DYLIB=ON \
          -DCLANG_LINK_CLANG_DYLIB=ON
        ninja install
      "
    '';

    installPhase = "touch $out/DONE";

    passthru = {
      clang-unwrapped = finalAttrs.finalPackage;
      llvm = finalAttrs.finalPackage;
      lld = finalAttrs.finalPackage;
      lib = finalAttrs.finalPackage;
    };
  });

in
{
  # This function takes an original NDK and replaces its toolchain with the source-built one
  mkSourceBuiltNdk =
    originalNdk:
    let
      # Propagate attributes that android-nixpkgs expects
      inherit (originalNdk) version path xml;
      installSdk = originalNdk.installSdk or "";
    in
    (pkgs.runCommand "${originalNdk.name}-source-built" { } ''
      cp --reflink=auto --no-preserve=ownership -r ${originalNdk} $out
      chmod -R u+w $out

      # The NDK structure has toolchains/llvm/prebuilt/linux-x86_64/
      # We want to replace the binaries there.

      targetDir=$out/libexec/android-sdk/ndk/${version}/toolchains/llvm/prebuilt/linux-x86_64
      if [ ! -d "$targetDir" ]; then
        # fallback for different structure
        targetDir=$out/share/android-sdk/ndk/${version}/toolchains/llvm/prebuilt/linux-x86_64
      fi

      if [ -d "$targetDir" ]; then
        rm -rf "$targetDir/bin"
        rm -rf "$targetDir/lib"
        mkdir -p "$targetDir/bin" "$targetDir/lib"
        
        # Link source-built toolchain
        ln -sf ${sourceBuiltLlvmDrv}/bin/* "$targetDir/bin/"
        ln -sf ${sourceBuiltLlvmDrv}/lib/* "$targetDir/lib/"
      fi
    '')
    // {
      inherit
        version
        path
        xml
        installSdk
        ;
    };
}
