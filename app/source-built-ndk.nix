{
  lib,
  stdenv,
  pkgs,
  robotnix,
}:
let
  aospLlvmBase = {
    version = "21.0.0";
    revision = "386af4a5c64ab75eaee2448dc38f2e34a40bfed0";
    hash = "sha256-30ZqBJ8zFWnGLFVsbI+hVqg2j4VS+pc3MTFbgpmz2ZY=";
  };

  aospLlvmSpecs = {
    "clang-r563880" = {
      llvmAndroidRevision = "79d2e9262fa5c751a95922d202d73e8a503d3761";
      llvmAndroidHash = "sha256-wMRJXuC4/Q/K5lvYEZL+HzWo5uA3FDwxVPWrS1YL2o8=";
      patchFiles = [
        "Add-cmake-c-cxx-asm-linker-flags-v2.patch"
        "Add-stubs-and-headers-for-nl_types-APIs-v2.patch"
        "BOLT-Increase-max-allocation-size-to-allow-BOLTing-clang-and-rustc.patch"
        "cherry/922f339c4ef3631f66dc4b8caa4c356103dbf69d.patch"
        "Disable-integer-sanitizer-for-__libcpp_blsr.patch"
        "Disable-std-utilities-charconv-charconv.msvc-test.pa.patch"
        "Disable-vfork-fork-events-v2.patch"
        "cherry/935bc84158e933239047de69b9edc77969b5c70c.patch"
        "cherry/488eeb3ae508221f8e476bbc9d2e9f014542862e.patch"
        "cherry/0227396417d4625bc93affdd8957ff8d90c76299.patch"
        "cherry/183acdd27985afd332463e3d9fd4a2ca46d85cf1.patch"
        "Revert-Driver-Allow-target-override-containing-.-in-executable-name-v2.patch"
        "Revert-Recommit-DAGCombiner-Transform-icmp-eq-ne-and.patch"
        "Revert-libc-Don-t-implement-stdatomic.h-before-C-23-.patch"
        "cherry/6c78dedc14e7431aa0dd92b9dd8d35bed3e0ed7d.patch"
        "cherry/c7995a6905f2320f280013454676f992a8c6f89f.patch"
        "cherry/2c43479683651f0eb208c97bf12e49bacbea4e6f.patch"
        "cherry/bf7af2d12e3bb8c7bc322ed1c5bf4e9904ad409c.patch"
        "cherry/107260cc29368070bba815d94f9d5b7cec1df7d0.patch"
        "cherry/8c7a2ce01a77c96028fe2c8566f65c45ad9408d3.patch"
        "cherry/86cf4ed7e9510a6828e95e8b36893eec116c9cf9-v2.patch"
        "cherry/b8d1f3d62746110ff0c969a136fc15f1d52f811d.patch"
        "cherry/27757fb87429c89a65bb5e1f619ad700928db0fd.patch"
        "cherry/8957e64a20fc7f4277565c6cfe3e555c119783ce.patch"
        "cherry/a76cf062a57097ad7971325551854bd5f3d38d94.patch"
        "cherry/9725595f3acc0c1aaa354e15ac4ee2b1f8ff4cc9.patch"
        "cherry/ba476d0b83dc8a4bbf066dc02a0f73ded27114f0.patch"
        "cherry/9ed4c705ac1c5c8797f328694f6cd22fbcdae03b.patch"
        "cherry/6bac20b391edce2bde348e59f5be2143157304b5.patch"
        "cherry/5da9044c40840187330526ca888290a95927a629.patch"
        "cherry/30f3752e54fa7cd595a434a985efbe9a7abe9b65.patch"
        "cherry/ccb08b9dab7d829f8d9703d8b46b98e2d6717d0e.patch"
        "cherry/13fe07d670e8a115929c9e595c4490ef5c75f583.patch"
        "cherry/bcfd9f81e1bc9954d616ffbb8625099916bebd5b.patch"
        "cherry/f00b32e2d0ee666d32f1ddd0c687e269fab95b44.patch"
        "cherry/a27f3b2bb137001735949549354aff89dbf227f4.patch"
        "cherry/8389d6fad76bd880f02bddce7f0f2612ff0afc40.patch"
        "compiler-rt-Allow-finding-LLVMConfig-if-CMAKE_FIND_ROOT_PATH_MODE_PACKAGE-is-set-to-ONLY.patch"
        "move-cxa-demangle-into-libcxxdemangle.patch"
      ];
    };
  };

  mkAospLlvmMonorepoSrc =
    clangVersion: spec:
    let
      llvmProjectSrc = pkgs.fetchgit {
        url = "https://github.com/llvm/llvm-project.git";
        rev = aospLlvmBase.revision;
        hash = aospLlvmBase.hash;
      };
      llvmAndroidSrc = pkgs.fetchgit {
        url = "https://android.googlesource.com/toolchain/llvm_android";
        rev = spec.llvmAndroidRevision;
        hash = spec.llvmAndroidHash;
      };
    in
    pkgs.runCommand "aosp-${clangVersion}-llvm-project-src"
      {
        nativeBuildInputs = [ pkgs.git ];
      }
      ''
        cp --reflink=auto --no-preserve=ownership -r ${llvmProjectSrc} $out
        chmod -R u+w $out

        git -C "$out" init -q
        git -C "$out" add -A
        git -C "$out" -c user.email=nix@example.org -c user.name=nix commit -q -m base

        patches=(${lib.escapeShellArgs spec.patchFiles})
        for patch_path in "''${patches[@]}"; do
          git -C "$out" apply -3 --apply ${llvmAndroidSrc}/patches/"$patch_path"
        done

        rm -rf "$out/.git"
      '';

  mkAospLlvmPackages =
    clangVersion: spec:
    (pkgs.llvmPackages_21.override {
      version = aospLlvmBase.version;
      officialRelease = { };
      monorepoSrc = mkAospLlvmMonorepoSrc clangVersion spec;
    }).overrideScope
      (
        _final: prev: {
          libllvm = prev.libllvm.overrideAttrs (old: {
            buildInputs = lib.unique ((old.buildInputs or [ ]) ++ [ pkgs.zstd ]);
            propagatedBuildInputs = lib.unique ((old.propagatedBuildInputs or [ ]) ++ [ pkgs.zstd ]);
            cmakeFlags = (old.cmakeFlags or [ ]) ++ [
              (lib.cmakeFeature "LLVM_ENABLE_ZSTD" "FORCE_ON")
            ];
          });

          clang-unwrapped = prev.clang-unwrapped.overrideAttrs (old: {
            buildInputs = lib.unique ((old.buildInputs or [ ]) ++ [ pkgs.zstd ]);
          });
        }
      );

  llvmPackagesByClangVersion = lib.mapAttrs mkAospLlvmPackages aospLlvmSpecs;

  # Use one of the clang versions as the "source-built" toolchain
  sourceBuiltLlvm = llvmPackagesByClangVersion."clang-r563880";

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
        for f in ${sourceBuiltLlvm.clang-unwrapped}/bin/*; do
          ln -sf "$f" "$targetDir/bin/"
        done
        for f in ${sourceBuiltLlvm.llvm}/bin/*; do
          ln -sf "$f" "$targetDir/bin/"
        done
        for f in ${sourceBuiltLlvm.lld}/bin/*; do
          ln -sf "$f" "$targetDir/bin/"
        done
        
        for f in ${sourceBuiltLlvm.clang-unwrapped.lib}/lib/*; do
          ln -sf "$f" "$targetDir/lib/"
        done
        for f in ${sourceBuiltLlvm.llvm.lib}/lib/*; do
          ln -sf "$f" "$targetDir/lib/"
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
