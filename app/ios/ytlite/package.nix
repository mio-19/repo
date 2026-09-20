{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchgit,
  gnumake,
  perl,
  dpkg,
  ldid,
}:

# Builds the YTLite (YouTube Plus) Theos tweak into a .deb.
#
# Needs host Xcode; __noChroot requires sandbox = relaxed (or false):
#   nix build .#ios_ytlite
let
  # Pin matches dayanch96/YTLite CI (.github/workflows/_build_tweaks.yml).
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

  youTubeHeader = fetchFromGitHub {
    owner = "PoomSmart";
    repo = "YouTubeHeader";
    rev = "340680d7e6023c051f912f884bc1879b84aca7c6";
    hash = "sha256-4xqKx2QCvwYzFb2i9BHXolHaghUjdq3WOu1QlqtO2/k=";
  };

  # Provides <roothide.h> / jbroot() used by Utils/NSBundle+YTLite.*;
  # stub path is selected when not building THEOS_PACKAGE_SCHEME=roothide.
  libroothide = fetchFromGitHub {
    owner = "roothide";
    repo = "libroothide";
    rev = "7764c54759009272b4f2f23c18c62b21794fe6dd";
    hash = "sha256-k3KS4/Dm9zw4mTNeOpBKRw/+QENIup6bhkxw6rl0gX0=";
  };

  # YTNativeShare.x imports ../protobuf/objectivec/*.h (same layout as
  # jkhsjdhjs/youtube-native-share). Headers only — not linked.
  protobufObjc = fetchgit {
    url = "https://github.com/protocolbuffers/protobuf.git";
    rev = "b8764f0941a6a5d500c48671716f0de81eb1dcaf";
    sparseCheckout = [ "objectivec" ];
    hash = "sha256-WM5+uVpbTKcm4hBb03mT3ZnxUooTtCaH1W72/8ZDzcU=";
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ytlite";
  version = "5.2.2";

  src = fetchFromGitHub {
    owner = "dayanch96";
    repo = "YTLite";
    tag = "v${finalAttrs.version}";
    hash = "sha256-FxDJ5xSXolCtX4xKjFoMYh1dtP6WZBCGxHWcwoqcZVw=";
  };

  # Host Xcode / codesign need out-of-sandbox access on Darwin.
  __noChroot = true;

  nativeBuildInputs = [
    gnumake
    perl
    dpkg
    ldid
  ];

  # YouTubeHeaders.h / YTNativeShare.x import sibling dirs via ../
  postUnpack = ''
    cp -a ${youTubeHeader} "$NIX_BUILD_TOP/YouTubeHeader"
    cp -a ${protobufObjc} "$NIX_BUILD_TOP/protobuf"
  '';

  postPatch = ''
    # Upstream Makefile hardcodes an old PACKAGE_VERSION; override via make/env.
    substituteInPlace Makefile \
      --replace-fail 'PACKAGE_VERSION = 3.0.1' 'PACKAGE_VERSION ?= 3.0.1' \
      --replace-fail \
        '$(TWEAK_NAME)_CFLAGS = -fobjc-arc -DTWEAK_VERSION=$(PACKAGE_VERSION)' \
        '$(TWEAK_NAME)_CFLAGS = -fobjc-arc -DTWEAK_VERSION=$(PACKAGE_VERSION) -Wno-deprecated-declarations'
  '';

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    if [[ "$(uname -s)" != Darwin ]]; then
      echo "ytlite requires Darwin + Xcode (Theos iphone toolchain)" >&2
      exit 1
    fi

    export THEOS="$NIX_BUILD_TOP/theos"
    cp -a ${theosSrc} "$THEOS"
    chmod -R u+w "$THEOS"
    mkdir -p "$THEOS/sdks"
    cp -a ${iphoneSdk}/iPhoneOS16.5.sdk "$THEOS/sdks/"

    # fetchgit strips .git; Theos before-all requires these marker files.
    touch "$THEOS/vendor/include/.git" "$THEOS/vendor/lib/.git"

    # Install RootHide headers (stub for rootful/rootless builds).
    mkdir -p "$THEOS/include/roothide"
    cp ${libroothide}/roothide-theos.h "$THEOS/include/roothide.h"
    cp ${libroothide}/roothide.h "$THEOS/include/roothide/roothide.h"
    cp ${libroothide}/stub.h "$THEOS/include/roothide/stub.h"

    # Prefer host Xcode (requires sandbox disabled / __noChroot).
    if [[ -z "''${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
      export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    fi

    # Host tools Theos shells out to (sysctl, xcrun, codesign, …).
    # Append so Nix coreutils (realpath, …) stay preferred during fixup.
    export PATH="$PATH:/usr/bin:/bin:/usr/sbin:/sbin"

    # Do not let Nix stdenv compiler wrappers interfere with Theos/xcrun.
    unset CC CXX NIX_CFLAGS_COMPILE NIX_LDFLAGS || true

    make package \
      DEBUG=0 \
      FINALPACKAGE=1 \
      PACKAGE_VERSION=${finalAttrs.version}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/debs"
    shopt -s nullglob
    debs=(packages/*.deb)
    if [[ ''${#debs[@]} -eq 0 ]]; then
      echo "no .deb produced under packages/" >&2
      exit 1
    fi
    mv "''${debs[@]}" "$out/debs/"
    # Convenience symlink to the primary package.
    primary=$(cd "$out/debs" && ls *.deb | head -n1)
    ln -s "debs/$primary" "$out/ytlite.deb"
    runHook postInstall
  '';

  meta = {
    description = "YouTube Plus (YTLite) — iOS YouTube enhancer tweak (Theos .deb)";
    homepage = "https://github.com/dayanch96/YTLite";
    # No LICENSE in upstream repo; treat as unfree.
    license = lib.licenses.unfree;
    platforms = lib.platforms.darwin;
  };
})
