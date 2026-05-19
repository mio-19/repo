{
  lib,
  stdenv,
  pkgs,
  robotnix,
  androidSdkBuilder,
}:
let
  sourceBuiltNdkReleases = {
    "28.2.13676358" = {
      llvmRevision = "r547379";
      llvmProjectRev = "b718bcaf8c198c82f3021447d943401e3ab5bd54";
      llvmProjectHash = "sha256-JkVEJgNmm0o4BIEVvFSztuutmYv4cCS32jO+ZZSwVpU=";
      buildId = "13676358";
    };
    "29.0.14206865" = {
      llvmRevision = "r563880c";
      llvmProjectRev = "5e96669f06077099aa41290cdb4c5e6fa0f59349";
      llvmProjectHash = "sha256-Efdy0nIa7h9ytmByCiBDju//SBe08lmo7NTwfdTUqG8=";
      buildId = "14206865";
    };
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

  # Build the host LLVM tools used by the NDK.  The source revision is the
  # Android release branch in toolchain/llvm-project, which already contains
  # the exact patch stack recorded by the matching llvm_android release branch.
  sourceBuiltLlvmDrv =
    release:
    stdenv.mkDerivation (finalAttrs: {
      pname = "aosp-llvm";
      version = release.llvmRevision;

      src = pkgs.fetchgit {
        url = "https://android.googlesource.com/toolchain/llvm-project";
        rev = release.llvmProjectRev;
        hash = release.llvmProjectHash;
      };

      nativeBuildInputs = [ sourceBuiltLlvmFhs ];

      buildPhase = ''
        runHook preBuild
        aosp-llvm-fhs -c "
          set -euo pipefail
          mkdir -p build
          cd build
          cmake ../llvm \
            -GNinja \
            -DCMAKE_C_COMPILER=gcc \
            -DCMAKE_CXX_COMPILER=g++ \
            -DCMAKE_C_FLAGS='-Wno-error=dangling-reference' \
            -DCMAKE_CXX_FLAGS='-Wno-error=dangling-reference' \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX=$out \
            -DCMAKE_INSTALL_LIBDIR=lib \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_PLATFORM_NO_VERSIONED_SONAME=ON \
            -DLLVM_ENABLE_PROJECTS='clang;clang-tools-extra;lld' \
            -DLLVM_TARGETS_TO_BUILD='AArch64;ARM;X86' \
            -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON \
            -DLLVM_ENABLE_ZSTD=ON \
            -DLLVM_ENABLE_TERMINFO=OFF \
            -DLLVM_ENABLE_PLUGINS=OFF \
            -DLLVM_VERSION_SUFFIX= \
            -DLLVM_PARALLEL_LINK_JOBS=1 \
            -DLLVM_BUILD_LLVM_DYLIB=ON \
            -DLLVM_LINK_LLVM_DYLIB=ON \
            -DCLANG_LINK_CLANG_DYLIB=ON \
            -DCLANG_VENDOR='Android (${release.buildId}, based on ${release.llvmRevision})' \
            -DCLANG_REPOSITORY_STRING='https://android.googlesource.com/toolchain/llvm-project' \
            -DCLANG_DEFAULT_LINKER=lld \
            -DCLANG_DEFAULT_OBJCOPY=llvm-objcopy \
            -DBUG_REPORT_URL='https://github.com/android-ndk/ndk/issues'
          ninja install
        "
        runHook postBuild
      '';

      installPhase = ''
        touch $out/DONE
      '';

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
      release =
        sourceBuiltNdkReleases.${version}
          or (throw "No source-built LLVM release metadata for NDK ${version}");
      sourceBuiltLlvm = sourceBuiltLlvmDrv release;
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
        # Preserve the NDK's target-prefixed clang driver shims and sysroot.
        for tool in ${sourceBuiltLlvm}/bin/*; do
          ln -sf "$tool" "$targetDir/bin/$(basename "$tool")"
        done
        for libPath in ${sourceBuiltLlvm}/lib/*; do
          ln -sf "$libPath" "$targetDir/lib/$(basename "$libPath")"
        done
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
