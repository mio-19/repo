{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  fetchgit,
  fetchurl,
  gnumake,
  perl,
  dpkg,
  ldid,
  openssl,
  writableTmpDirAsHomeHook,
  # When true (default), include Lessica dyld/systemhook patches so
  # DYLD_FRAMEWORK_PATH can override DSC frameworks (WebKitPlayground).
  # ios_dopamine_upstream sets this to false for vanilla opa334 Dopamine.
  withWebKitPlaygroundPatches ? true,
}:

# Builds opa334/Dopamine (jailbreak IPA / tipa).
#
# Needs host Xcode; __noChroot requires sandbox = relaxed (or false):
#   nix build .#ios_dopamine
#   nix build .#ios_dopamine_upstream   # withWebKitPlaygroundPatches = false
let
  # Pin matches dayanch96/YTLite CI / Dopamine CI (iPhoneOS16.5.sdk).
  theosSrc = fetchgit {
    url = "https://github.com/theos/theos.git";
    rev = "9bc73406cf80b711ef4d02c15ff1dedc4478a275";
    fetchSubmodules = true;
    hash = "sha256-cr7QrUgenT4+Rs93fn/HDHq6p11lq9g5u4OuLUg6p90=";
  };

  iphoneSdk = fetchgit {
    url = "https://github.com/theos/sdks.git";
    rev = "0222fd5413cf4b9af096f37b4621afa2688572f7";
    sparseCheckout = [ "iPhoneOS16.5.sdk" ];
    hash = "sha256-OZzqnz+DAdEA6BVNdKv1oncHLhFVINKVi+zN33+uyp4=";
  };

  bootstrap1800 = fetchurl {
    url = "https://apt.procurs.us/bootstraps/1800/bootstrap-iphoneos-arm64.tar.zst";
    hash = "sha256-qZs5uwNE7jtCu5YTJQONzq59quxQCXbzuCLPNszPAgo=";
  };

  bootstrap1900 = fetchurl {
    url = "https://apt.procurs.us/bootstraps/1900/bootstrap-iphoneos-arm64.tar.zst";
    hash = "sha256-g1TDqh7NrY68R9mnbfym+DCit1cngGi9M7mL8dY4qcs=";
  };

  # Pins from BaseBin/*/Package.resolved (vendored so the build needs no network).
  swiftUtils = fetchFromGitHub {
    owner = "pinauten";
    repo = "SwiftUtils";
    rev = "1d37faabb4c58b3152394c9b6e1c1a68507646b9";
    hash = "sha256-o0Zu4IqLTYX+oRskNl9V6tH39sL8YyjVGU4Y/hjQbsA=";
  };

  swiftMachO = fetchFromGitHub {
    owner = "pinauten";
    repo = "SwiftMachO";
    rev = "cbfb1886c14bfb28c54034b43e49807ab7c17f11";
    hash = "sha256-FhSiJaeGerr4KkZjkr5/M3x4ydUxYNHmWdc6nin31QE=";
  };

  patchfinderUtils = fetchFromGitHub {
    owner = "pinauten";
    repo = "PatchfinderUtils";
    rev = "83647509e12001e8f42b2a5dc46b40977e12098b";
    hash = "sha256-lWkGv4xAE2UDbsUMZ49m1+kzZWHuFAGVEWdVoz0zj3o=";
  };

  iDownload = fetchFromGitHub {
    owner = "pinauten";
    repo = "iDownload";
    rev = "62920e864f06af4b0a50a0aa9b6e0a7c7bd83a6f";
    hash = "sha256-zHqQvBbnzky9r5S6Kq4U/8EqHSGK/Hx8cGcqIu9IzSg=";
  };

  # Host tool used by BaseBin to build basebin.tc (see Dopamine CI).
  trustcache = stdenv.mkDerivation {
    pname = "trustcache";
    version = "0-unstable-2023-02-12";

    src = fetchFromGitHub {
      owner = "CRKatri";
      repo = "trustcache";
      rev = "aa0e8847529cf76576fce8d2dbc9e088c8f1a0df";
      hash = "sha256-gsjbEWEAttjX0sWMnOGB/AeNrx7jo3JLCGC0YyYoYWA=";
    };

    buildInputs = [ openssl ];

    makeFlags = [ "OPENSSL=1" ];

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin"
      mv trustcache "$out/bin/"
      runHook postInstall
    '';

    meta = {
      description = "Create and manipulate Apple trust caches";
      homepage = "https://github.com/CRKatri/trustcache";
      license = lib.licenses.mit;
      platforms = lib.platforms.darwin;
    };
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "dopamine";
  version = "3.0.9";

  src = fetchFromGitHub {
    owner = "opa334";
    repo = "Dopamine";
    tag = finalAttrs.version;
    fetchSubmodules = true;
    hash = "sha256-D5+kCg6HlgHDwrZdsOVUBohHKZ468zeyqycJBb2CFVA=";
  };

  # Host Xcode / codesign need out-of-sandbox access on Darwin.
  __noChroot = true;

  nativeBuildInputs = [
    gnumake
    perl
    dpkg
    ldid
    trustcache
    writableTmpDirAsHomeHook
  ];

  patches = [
    ./0001-pbxproj-nixbld.patch
    ./0002-application-makefile.patch
    ./0003-idownloadd-swiftpm.patch
    ./0004-libarchive-include.patch
    ./0005-machomerger-nosandbox.patch
    ./0006-machomerger-local-spm.patch
  ]
  ++ lib.optionals withWebKitPlaygroundPatches [
    # Port of Lessica/Dopamine feat/dyld-framework-overrides for opa334 rootless —
    # required by https://github.com/Lessica/WebKitPlayground (DYLD_FRAMEWORK_PATH over DSC).
    ./0007-webkit-dyldhook-trampolines.patch
    ./0008-webkit-framework-override.patch
    ./0009-webkit-systemhook-dyld-framework-path.patch
  ];

  postPatch = ''
    # Vendor SwiftPM deps under BaseBin/_spm (path deps; no build-time network).
    mkdir -p BaseBin/_spm
    cp -a ${swiftUtils} BaseBin/_spm/SwiftUtils
    cp -a ${swiftMachO} BaseBin/_spm/SwiftMachO
    cp -a ${patchfinderUtils} BaseBin/_spm/PatchfinderUtils
    cp -a ${iDownload} BaseBin/_spm/iDownload
    chmod -R u+w BaseBin/_spm

    substituteInPlace BaseBin/_spm/SwiftMachO/Package.swift \
      --replace-fail \
        '.package(name: "SwiftUtils", url: "https://github.com/pinauten/SwiftUtils", .branch("master"))' \
        '.package(name: "SwiftUtils", path: "../SwiftUtils")'

    substituteInPlace BaseBin/_spm/PatchfinderUtils/Package.swift \
      --replace-fail \
        '.package(name: "SwiftUtils", url: "https://github.com/pinauten/SwiftUtils", .branch("master")),' \
        '.package(name: "SwiftUtils", path: "../SwiftUtils"),' \
      --replace-fail \
        '.package(name: "SwiftMachO", url: "https://github.com/pinauten/SwiftMachO", .branch("master"))' \
        '.package(name: "SwiftMachO", path: "../SwiftMachO")'

    substituteInPlace BaseBin/_spm/iDownload/Package.swift \
      --replace-fail \
        '.package(name: "SwiftUtils", url: "https://github.com/pinauten/SwiftUtils", .branch("master"))' \
        '.package(name: "SwiftUtils", path: "../SwiftUtils")'

    # idownloadd Package.swift expects ./iDownload; SPM resolves iDownload's
    # path deps relative to the symlink location (not the realpath), so also
    # expose SwiftUtils beside it.
    ln -s ../_spm/iDownload BaseBin/idownloadd/iDownload
    ln -s ../_spm/SwiftUtils BaseBin/idownloadd/SwiftUtils

    # Prebuilt asset catalog (Assets.car).
    # Why we don't compile this during the build:
    # `actool` relies on `CoreSimulatorService`, which is spawned out-of-process
    # by launchd. launchd resolves the nixbld user's home directory by querying
    # the macOS passwd database (which is hardcoded to /var/empty).
    # It completely ignores the $HOME or SIMULATOR_DEVICE_SET_PATH environment
    # variables in our shell. It crashes trying to write to /var/empty/Library.
    # SIP prevents us from hooking getpwuid() via DYLD_INSERT_LIBRARIES.
    # Therefore, we provide a precompiled Assets.car and inject CFBundleIcons via plutil.
    cp -f ${./Assets.car} Application/prebuilt-Assets.car
  '';

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    if [[ "$(uname -s)" != Darwin ]]; then
      echo "dopamine requires Darwin + Xcode" >&2
      exit 1
    fi

    # Force a writable home; SwiftPM warns on /var/empty but still builds.
    export HOME="$NIX_BUILD_TOP/.home"
    mkdir -p "$HOME/Library/Caches/org.swift.swiftpm" \
      "$HOME/Library/org.swift.swiftpm" \
      "$HOME/Library/Developer/Xcode/DerivedData"
    export SWIFTPM_DISABLE_SANDBOX=1

    export THEOS="$NIX_BUILD_TOP/theos"
    cp -a ${theosSrc} "$THEOS"
    chmod -R u+w "$THEOS"
    mkdir -p "$THEOS/sdks"
    cp -a ${iphoneSdk}/iPhoneOS16.5.sdk "$THEOS/sdks/"

    # fetchgit strips .git; Theos before-all requires these marker files.
    touch "$THEOS/vendor/include/.git" "$THEOS/vendor/lib/.git"

    # Prefer host Xcode (requires sandbox disabled / __noChroot).
    if [[ -z "''${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
      export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    fi

    # Host tools Theos / xcrun / codesign shell out to.
    # Append so Nix coreutils (realpath, …) stay preferred during fixup.
    export PATH="$PATH:/usr/bin:/bin:/usr/sbin:/sbin"

    # Do not let Nix stdenv compiler wrappers interfere with Theos/xcrun.
    unset CC CXX NIX_CFLAGS_COMPILE NIX_LDFLAGS || true

    # Procursus bootstraps (normally downloaded by download_bootstraps.sh).
    cp -f ${bootstrap1800} Application/Dopamine/Resources/bootstrap_1800.tar.zst
    cp -f ${bootstrap1900} Application/Dopamine/Resources/bootstrap_1900.tar.zst

    make -j''${NIX_BUILD_CORES:-1} NIGHTLY=0

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    shopt -s nullglob
    for f in Application/Dopamine.ipa Application/Dopamine.tipa Standalone/Dopamine.tar; do
      if [[ -e "$f" ]]; then
        mv "$f" "$out/"
      fi
    done
    if [[ ! -e "$out/Dopamine.ipa" && ! -e "$out/Dopamine.tipa" ]]; then
      echo "no Dopamine.ipa/tipa produced" >&2
      exit 1
    fi
    runHook postInstall
  '';

  meta = {
    description =
      if withWebKitPlaygroundPatches then
        "Dopamine — semi-untethered iOS jailbreak (IPA), with WebKitPlayground dyld patches"
      else
        "Dopamine — semi-untethered iOS jailbreak (IPA), upstream/vanilla";
    homepage = "https://github.com/opa334/Dopamine";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
  };
})
