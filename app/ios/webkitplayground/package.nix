{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  python3,
  perl,
  ruby,
  dpkg,
  ldid,
  git,
  cacert,
  writableTmpDirAsHomeHook,
  # Target iOS version: "16.3.1" (Lessica official patch) or "18.6.1" (ported).
  targetIOS ? "16.3.1",
}:

# Builds Lessica/WebKitPlayground into a rootless .deb for Dopamine
# (frameworks under /var/jb/Library/Frameworks).
#
# Needs host Xcode; __noChroot requires sandbox = relaxed (or false):
#   nix build .#ios_webkitplayground           # iOS 16.3.1 (iPhone 13)
#   nix build .#ios_webkitplayground_18_6_1    # iOS 18.6.1 (iPhone 11)
#
# Pair with ios_dopamine (withWebKitPlaygroundPatches = true).
assert builtins.elem targetIOS [
  "16.3.1"
  "18.6.1"
];

let
  playground = fetchFromGitHub {
    owner = "Lessica";
    repo = "WebKitPlayground";
    rev = "b447a3a64d7a08167bbc858d7ede7c7568c4ae02";
    hash = "sha256-dkpUQZDB5Jgv7P8NlXFx03e5BCzLQYKRUa89QFFLqpA=";
  };

  # GitHub archive API returns 422 for large WebKit/WebKit tags; shallow-clone FOD.
  fetchWebKitShallow =
    {
      name,
      rev,
      hash,
    }:
    stdenvNoCC.mkDerivation {
      inherit name;
      nativeBuildInputs = [
        git
        cacert
      ];
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = hash;
      preferLocalBuild = true;
      allowSubstitutes = false;
      impureEnvVars = lib.fetchers.proxyImpureEnvVars;
      buildCommand = ''
        set -euo pipefail
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        git clone --depth 1 --branch ${lib.escapeShellArg rev} \
          https://github.com/WebKit/WebKit.git "$out"
        rm -rf "$out/.git"
      '';
    };

  # Sparse Tools/ overlay for apple-oss drops (which omit Tools/).
  fetchWebKitToolsShallow =
    {
      name,
      rev,
      hash,
    }:
    stdenvNoCC.mkDerivation {
      inherit name;
      nativeBuildInputs = [
        git
        cacert
      ];
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = hash;
      preferLocalBuild = true;
      allowSubstitutes = false;
      impureEnvVars = lib.fetchers.proxyImpureEnvVars;
      buildCommand = ''
        set -euo pipefail
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME" "$out"
        git clone --depth 1 --filter=blob:none --sparse \
          --branch ${lib.escapeShellArg rev} \
          https://github.com/WebKit/WebKit.git "$TMPDIR/webkit"
        git -C "$TMPDIR/webkit" sparse-checkout set Tools
        cp -a "$TMPDIR/webkit/Tools" "$out/Tools"
      '';
    };

  webkit163 = fetchWebKitShallow {
    name = "webkit-16.3.1";
    rev = "releases/Apple/Safari-16.3-iOS-16.3.1";
    # NAR hash of shallow checkout with .git removed.
    hash = "sha256-D7f011qRoo68UhE8CPfxMqVI0HiW4iGhseKjcwp5qsQ=";
  };

  # Safari 18.6 ≈ WebKit 621.3.11 (apple-oss); no Safari-18.6 tag on WebKit/WebKit yet.
  webkit186 = fetchFromGitHub {
    owner = "apple-oss-distributions";
    repo = "WebKit";
    tag = "WebKit-7621.3.11.11.3";
    hash = "sha256-IEVOS++Uhz4wjb9igT1/PrgR5EFQ6CddRhswaBQbIiQ=";
  };

  webkitTools183 = fetchWebKitToolsShallow {
    name = "webkit-tools-18.3.2";
    rev = "releases/Apple/Safari-18.3.1-iOS-18.3.2";
    hash = "sha256-NurZDDsbEVwIkJwPF1LThLWxWJEaIwuBo6C4KYS7gfs=";
  };

  versionSuffix = builtins.replaceStrings [ "." ] [ "_" ] targetIOS;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "webkitplayground-${versionSuffix}";
  version = if targetIOS == "16.3.1" then "16.3.1" else "18.6.1-621.3.11";

  src = playground;

  __noChroot = true;

  nativeBuildInputs = [
    python3
    perl
    ruby
    dpkg
    ldid
    git
    writableTmpDirAsHomeHook
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    if [[ "$(uname -s)" != Darwin ]]; then
      echo "webkitplayground requires Darwin + Xcode" >&2
      exit 1
    fi

    export HOME="$NIX_BUILD_TOP/.home"
    mkdir -p "$HOME"

    if [[ -z "''${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
      export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    fi
    export PATH="$PATH:/usr/bin:/bin:/usr/sbin:/sbin"
    unset CC CXX NIX_CFLAGS_COMPILE NIX_LDFLAGS || true

    # Layout expected by Lessica patches (abi-shims via ../../../scripts/...).
    rm -rf WebKit
    ${
      if targetIOS == "16.3.1" then
        ''
          cp -a ${webkit163} WebKit
          chmod -R u+w WebKit
          echo "Applying Lessica iOS 16.3.1 patch..."
          git apply --verbose --directory=WebKit patches/webkit_iOS_16.3.1-worktree-20260412-004539.patch
        ''
      else
        ''
          cp -a ${webkit186} WebKit
          chmod -R u+w WebKit
          rm -rf WebKit/Tools
          cp -a ${webkitTools183}/Tools WebKit/Tools
          chmod -R u+w WebKit/Tools
          echo "Applying ported iOS 18.6.1 patch..."
          git apply --verbose --directory=WebKit ${./webkit_iOS_18.6.1-ported.patch}
        ''
    }

    # Xcode 26+ workarounds (generated via diff against upstream WebKit sources).
    git apply --verbose --directory=WebKit ${./0001-unified-sources-wtf-scripts-fallback.patch}
    git apply --verbose --directory=WebKit ${./0002-build-webkit-all-source-scheme.patch}
    ${
      if targetIOS == "16.3.1" then
        ''
          git apply --verbose --directory=WebKit ${./0003-xpcspi-prefer-system-xpc-h.patch}
          git apply --verbose --directory=WebKit ${./0005-segmentedvector-iterator-traits.patch}
          git apply --verbose --directory=WebKit ${./0006-angle-reference-pointer-ops.patch}
        ''
      else
        ''
          git apply --verbose --directory=WebKit ${./0004-xpcspi-mach-service-ios-shim.patch}
        ''
    }

    # Public iPhoneOS SDKs omit several objc/*.h that older WebKit still includes.
    # Provide them via -isystem from the companion MacOSX SDK (configure-xcode-for-
    # embedded-development used to do this; it is a no-op on modern Xcode).
    OBJC_SHIM="$NIX_BUILD_TOP/objc-shim/usr/include"
    mkdir -p "$OBJC_SHIM/objc"
    MAC_OBJC="$(xcrun --sdk macosx --show-sdk-path)/usr/include/objc"
    for h in Protocol.h List.h hashtable.h hashtable2.h objc-class.h objc-load.h Object.h objc-runtime.h; do
      if [[ -f "$MAC_OBJC/$h" ]]; then
        cp "$MAC_OBJC/$h" "$OBJC_SHIM/objc/$h"
      fi
    done
    if [[ ! -f "$OBJC_SHIM/objc/objc-runtime.h" ]]; then
      printf '%s\n' '#include <objc/runtime.h>' > "$OBJC_SHIM/objc/objc-runtime.h"
    fi

    echo "Building WebKit for iphoneos (long-running)..."
    (
      cd WebKit
      # Seed WTF Scripts before the first Generate Unified Sources phase.
      mkdir -p WebKitBuild/Release-iphoneos/usr/local/include/wtf/Scripts
      cp -a Source/WTF/Scripts/. WebKitBuild/Release-iphoneos/usr/local/include/wtf/Scripts/

      # Build only the frameworks needed for the device deb — skip WebInspectorUI /
      # test targets which race on InspectorBackendCommands.js under Xcode 26.
      export SDKROOT=iphoneos
      export ONLY_ACTIVE_ARCH=NO
      export CODE_SIGN_IDENTITY="-"
      export CODE_SIGNING_REQUIRED=NO
      export CODE_SIGNING_ALLOWED=NO
      export GCC_TREAT_WARNINGS_AS_ERRORS=NO
      export IPHONEOS_DEPLOYMENT_TARGET=16.0

      common=(
        -workspace WebKit.xcworkspace
        -configuration Release
        -derivedDataPath "$PWD/DerivedData"
        SUPPORTS_TEXT_BASED_API=NO
        OTHER_CFLAGS='$(inherited) -Wno-error -Wno-enum-constexpr-conversion -Wno-missing-template-arg-list-after-template-kw -isystem '"$OBJC_SHIM"
        OTHER_CPLUSPLUSFLAGS='$(inherited) -Wno-error -Wno-enum-constexpr-conversion -Wno-missing-template-arg-list-after-template-kw -isystem '"$OBJC_SHIM"
        SYMROOT="$PWD/WebKitBuild"
        OBJROOT="$PWD/WebKitBuild"
        SHARED_PRECOMPS_DIR="$PWD/WebKitBuild/PrecompiledHeaders"
      )
      
      # Disable interactive jsc build to prevent readline errors on iOS SDK
      sed -i.bak 's/#define HAVE_READLINE 1/#define HAVE_READLINE 0/g' Source/WTF/wtf/PlatformHave.h

      for scheme in bmalloc WTF JavaScriptCore ANGLE WebCore WebKitLegacy WebKit; do
        echo "=== xcodebuild -scheme $scheme ==="
        xcodebuild -scheme "$scheme" "''${common[@]}"
      done
    )

    PRODUCT="WebKit/WebKitBuild/Release-iphoneos"
    if [[ ! -d "$PRODUCT" ]]; then
      echo "missing product dir: $PRODUCT" >&2
      ls -la WebKit/WebKitBuild 2>/dev/null || true
      exit 1
    fi

    chmod +x scripts/package-webkit-device-deb.sh
    scripts/package-webkit-device-deb.sh \
      --product "$PRODUCT" \
      --rootless \
      --id "com.82flex.custom-webkit" \
      --name "Custom WebKit (iOS ${targetIOS})" \
      --version "${finalAttrs.version}" \
      --author "WebKitPlayground (nix)" \
      --output "$NIX_BUILD_TOP/custom-webkit.deb"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/debs"
    mv "$NIX_BUILD_TOP/custom-webkit.deb" "$out/debs/custom-webkit.deb"
    ln -s "debs/custom-webkit.deb" "$out/webkitplayground.deb"
    runHook postInstall
  '';

  meta = {
    description = "WebKitPlayground custom WebKit rootless .deb for Dopamine (iOS ${targetIOS})";
    homepage = "https://github.com/Lessica/WebKitPlayground";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.darwin;
  };
})
