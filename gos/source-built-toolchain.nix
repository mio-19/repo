{
  config,
  pkgs,
  lib,
  robotnix,
  ...
}:
let
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

    "clang-r563880c" = {
      llvmAndroidRevision = "38546691df970516709cc907bc7387004f69c60c";
      llvmAndroidHash = "sha256-hjJOQkER2aPl79DoE+4RsIBgdOAk7ZLUW6xMzlisEX4=";
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
        "cherry/d8e8ab79773f739c602c5869f80c6c5b5962c558.patch"
        "cherry/0227396417d4625bc93affdd8957ff8d90c76299.patch"
        "cherry/183acdd27985afd332463e3d9fd4a2ca46d85cf1.patch"
        "Revert-Driver-Allow-target-override-containing-.-in-executable-name-v2.patch"
        "Revert-Recommit-DAGCombiner-Transform-icmp-eq-ne-and.patch"
        "Revert-libc-Don-t-implement-stdatomic.h-before-C-23-.patch"
        "cherry/6c78dedc14e7431aa0dd92b9dd8d35bed3e0ed7d.patch"
        "cherry/ff85dbdf6b399eac7bffa13e579f0f5e6edac3c0.patch"
        "cherry/43c85afce9c25141de79da6731b1d5f8bb2491b1.patch"
        "cherry/c7995a6905f2320f280013454676f992a8c6f89f.patch"
        "cherry/2c43479683651f0eb208c97bf12e49bacbea4e6f.patch"
        "cherry/bf7af2d12e3bb8c7bc322ed1c5bf4e9904ad409c.patch"
        "cherry/107260cc29368070bba815d94f9d5b7cec1df7d0.patch"
        "cherry/8c7a2ce01a77c96028fe2c8566f65c45ad9408d3.patch"
        "cherry/b5cf03033251a642b184b2e0ea6bdac171c17702.patch"
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
        "cherry/8b3d4bdf8bade1d1faa8ff3fcbdda7060f8b46d8.patch"
        "cherry/2a83cf5d0e592890f74c5d5ff4a30ae4cf54b61b.patch"
        "cherry/ccb08b9dab7d829f8d9703d8b46b98e2d6717d0e.patch"
        "cherry/13fe07d670e8a115929c9e595c4490ef5c75f583.patch"
        "cherry/f5e687d7bf49cd9fe38ba7acdeb52d4f30468dee.patch"
        "cherry/769c42f4a552a75c8c38870ddc1b50d2ea874e4e.patch"
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

  mkToolchainPaths =
    llvm:
    let
      clangBin = lib.getBin llvm.clang-unwrapped;
      clangLib = llvm.clang-unwrapped.lib;
      clangPython = llvm.clang-unwrapped.python;
      llvmBin = lib.getBin llvm.llvm;
      llvmLib = llvm.llvm.lib;
      lldBin = lib.getBin llvm.lld;
      clangToolsBin = lib.getBin llvm.clang-tools;
    in
    {
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
        "git-clang-format" = "${clangPython}/bin/git-clang-format";
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
        "scan-view" = "${clangPython}/bin/scan-view";
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

      clangStableLinks = {
        "bin/clang-format" = "${clangToolsBin}/bin/clang-format";
        "bin/git-clang-format" = "${clangPython}/bin/git-clang-format";
        "lib/libclang.so" = "${clangLib}/lib/libclang.so";
        "share/clang/clang-format-diff.py" = "${clangPython}/share/clang/clang-format-diff.py";
        "share/clang/clang-format-sublime.py" = "${clangPython}/share/clang/clang-format-sublime.py";
        "share/clang/clang-format.py" = "${clangPython}/share/clang/clang-format.py";
        "share/clang/clang-include-fixer.py" = "${clangPython}/share/clang/clang-include-fixer.py";
        "share/clang/clang-tidy-diff.py" = "${clangPython}/share/clang/clang-tidy-diff.py";
        "share/clang/run-find-all-symbols.py" = "${clangPython}/share/clang/run-find-all-symbols.py";
      };
    };

  toolchainPathsByClangVersion = lib.mapAttrs (_: mkToolchainPaths) llvmPackagesByClangVersion;

  sourceBuiltClangHostLinuxX86 =
    let
      original = originalGrapheneosConfig.source.dirs."prebuilts/clang/host/linux-x86".src;
      stableToolchainPaths = toolchainPathsByClangVersion."clang-r563880";
    in
    pkgs.runCommand "grapheneos-prebuilts-clang-host-linux-x86-source-built" { } ''
      cp --reflink=auto --no-preserve=ownership -r ${original} $out
      chmod -R u+w $out

      ${lib.concatStringsSep "\n\n" (
        lib.mapAttrsToList (dir: toolchainPaths: ''
          mkdir -p "$out/${dir}/bin" "$out/${dir}/lib"
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: path: ''
              if [ -e ${path} ]; then
                rm -f "$out/${dir}/bin/${name}"
                ln -s ${path} "$out/${dir}/bin/${name}"
              fi
            '') toolchainPaths.toolLinks
          )}

          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: path: ''
              if [ -e ${path} ]; then
                rm -f "$out/${dir}/lib/${name}"
                ln -s ${path} "$out/${dir}/lib/${name}"
              fi
            '') toolchainPaths.hostLibLinks
          )}
        '') toolchainPathsByClangVersion
      )}

      rm -rf "$out/llvm-binutils-stable"
      mkdir -p "$out/llvm-binutils-stable"
      for tool in llvm-addr2line llvm-ar llvm-as llvm-cov llvm-cxxfilt llvm-dis llvm-dwarfdump llvm-link llvm-modextract llvm-nm llvm-objcopy llvm-objdump llvm-profdata llvm-ranlib llvm-readelf llvm-readobj llvm-size llvm-strings llvm-strip llvm-symbolizer; do
        if [ -e "$out/clang-r563880/bin/$tool" ]; then
          ln -s "../clang-r563880/bin/$tool" "$out/llvm-binutils-stable/$tool"
        fi
      done

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (path: target: ''
          if [ -e ${target} ]; then
            mkdir -p "$(dirname "$out/clang-stable/${path}")"
            rm -f "$out/clang-stable/${path}"
            ln -s ${target} "$out/clang-stable/${path}"
          fi
        '') stableToolchainPaths.clangStableLinks
      )}
    '';
in
{
  options.useSourceBuiltToolchain = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Replace GrapheneOS's host LLVM toolchain prebuilts with nixpkgs-packaged
      LLVM 21 builds synthesized from AOSP's upstream base revision and
      llvm_android patch stacks while preserving the Android-target runtime
      payload bundled in AOSP's prebuilt tree.
    '';
  };

  config = lib.mkIf config.useSourceBuiltToolchain {
    source.dirs."prebuilts/clang/host/linux-x86" = lib.mkForce {
      src = sourceBuiltClangHostLinuxX86;
    };
  };
}
