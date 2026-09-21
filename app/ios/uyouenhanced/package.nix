{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchgit,
  fetchurl,
  gnumake,
  perl,
  python3,
  dpkg,
  ldid,
  unzip,
  writableTmpDirAsHomeHook,
}:

# Builds arichornlover/uYouEnhanced into a sideloadable IPA (Theos jailed).
#
# Needs host Xcode; __noChroot requires sandbox = relaxed (or false):
#   nix build .#ios_uyouenhanced
let
  youtubeVersion = "21.37.5";
  uyouVersion = "3.0.4";
  sdkVersion = "18.6";

  # Tip includes Makefile inject-list fixes; tag v21.14.4-3.0.5 is older.
  src = fetchFromGitHub {
    owner = "arichornlover";
    repo = "uYouEnhanced";
    rev = "7da4c0a58b146082427860dfd22ae56cabcc4a08";
    fetchSubmodules = true;
    hash = "sha256-nprb62PmGdROiyRLcWlws0tIAxzk/VHyQOiOOolkCE4=";
  };

  theosSrc = fetchgit {
    url = "https://github.com/theos/theos.git";
    rev = "9bc73406cf80b711ef4d02c15ff1dedc4478a275";
    fetchSubmodules = true;
    hash = "sha256-cr7QrUgenT4+Rs93fn/HDHq6p11lq9g5u4OuLUg6p90=";
  };

  # CI uses aricloverALT/sdks (has iPhoneOS18.6.sdk); theos/sdks stops at 16.5.
  iphoneSdk = fetchgit {
    url = "https://github.com/aricloverALT/sdks.git";
    rev = "1b92ff4a8928f582876e1d388d1381c6a0c59eb9";
    sparseCheckout = [ "iPhoneOS${sdkVersion}.sdk" ];
    hash = "sha256-54ykr28DqLVpt5+43NQKdtAA+M2+vSp3q+QqeA9PC3Y=";
  };

  theosJailed = fetchFromGitHub {
    owner = "qnblackcat";
    repo = "theos-jailed";
    rev = "662fd704aed27b8956bcfe52a35e2b676921ab42";
    hash = "sha256-88q+QXl4VJg9tJnClKQBCEPSidF2v8ep4VpjdfEN/1Y=";
  };

  # Vendored by theos-jailed install (normally curled from apt.saurik.com).
  cydiaSubstrateDeb = fetchurl {
    url = "http://apt.saurik.com/debs/mobilesubstrate_0.9.6301_iphoneos-arm.deb";
    hash = "sha256-jckaBm8IhjJAn+z2VhODG41oAuO3mfLch1Y8PqLtBso=";
  };

  # Makefile before-all downloads this from Dropbox; pin as FOD instead.
  uyouDeb = fetchurl {
    url = "https://www.dropbox.com/scl/fi/01vvu5lm8nkkicrznku9v/com.miro.uyou_${uyouVersion}_iphoneos-arm.deb?rlkey=efgz7po8kqqvha8doplk1s3ky&dl=1";
    name = "com.miro.uyou_${uyouVersion}_iphoneos-arm.deb";
    hash = "sha256-C1U5zImKWnTLEpZ36aykIL0d+1XbwG/QGn3SY+dhiwc=";
  };

  youtubeIpa = fetchurl {
    url = "https://ia600907.us.archive.org/4/items/com.google.ios.youtube_21.37.5_und3fined_202609/com.google.ios.youtube_21.37.5_und3fined.ipa";
    hash = "sha256-bQiRSkrrPdXy57PZc61pgeWopXyaDc3ggVD4gAxhpTg=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "uyouenhanced";
  version = "${youtubeVersion}-${uyouVersion}";

  inherit src;

  # Host Xcode / codesign need out-of-sandbox access on Darwin.
  __noChroot = true;

  nativeBuildInputs = [
    gnumake
    perl
    python3
    dpkg
    ldid
    unzip
    writableTmpDirAsHomeHook
  ];

  dontConfigure = true;

  postPatch = ''
    # Injected dylibs that exist under Tweaks/ but were missing from SUBPROJECTS.
    substituteInPlace Makefile \
      --replace-fail \
        'Tweaks/YouLoop Tweaks/YouPiP' \
        'Tweaks/YouLoop Tweaks/YouMute Tweaks/YouPiP' \
      --replace-fail \
        'Tweaks/YouTimeStamp Tweaks/YTVideoOverlay' \
        'Tweaks/YouTimeStamp Tweaks/YTHoldForSpeed Tweaks/YTVideoOverlay'

    # Pre-extract uYou (Nix gnutar cannot open .deb/ar; Makefile uses tar -xf).
    mkdir -p Tweaks/uYou
    cp -f ${uyouDeb} Tweaks/uYou/com.miro.uyou_${uyouVersion}_iphoneos-arm.deb
    dpkg-deb -x Tweaks/uYou/com.miro.uyou_${uyouVersion}_iphoneos-arm.deb Tweaks/uYou
  '';

  buildPhase = ''
    runHook preBuild

    if [[ "$(uname -s)" != Darwin ]]; then
      echo "uyouenhanced requires Darwin + Xcode" >&2
      exit 1
    fi

    export HOME="$NIX_BUILD_TOP/.home"
    mkdir -p "$HOME/Library/Developer/Xcode/DerivedData"

    export THEOS="$NIX_BUILD_TOP/theos"
    cp -a ${theosSrc} "$THEOS"
    chmod -R u+w "$THEOS"
    mkdir -p "$THEOS/sdks"
    cp -a ${iphoneSdk}/iPhoneOS${sdkVersion}.sdk "$THEOS/sdks/"
    touch "$THEOS/vendor/include/.git" "$THEOS/vendor/lib/.git"

    # Xcode 26.3: generic/platform=iOS fails ("iOS 26.2 is not installed") even though
    # -sdk iphoneos works. Theos already passes -sdk; drop the destination selector.
    substituteInPlace "$THEOS/makefiles/instance/xcodeproj.mk" \
      --replace-fail \
        "-destination '\$(or \$(\$(THEOS_CURRENT_INSTANCE)_DESTINATION),generic/platform=iOS)' \\" \
        "\\"

    # Keep Xcode DerivedData off /var/empty (nixbld NSHomeDirectory).
    export ADDITIONAL_XCODEFLAGS="-derivedDataPath $HOME/Library/Developer/Xcode/DerivedData"

    # Install theos-jailed module with vendored CydiaSubstrate (no network).
    jailed="$NIX_BUILD_TOP/theos-jailed"
    cp -a ${theosJailed} "$jailed"
    chmod -R u+w "$jailed"
    mkdir -p "$jailed/module/lib" "$NIX_BUILD_TOP/substrate-extract"
    dpkg-deb -x ${cydiaSubstrateDeb} "$NIX_BUILD_TOP/substrate-extract"
    mv "$NIX_BUILD_TOP/substrate-extract/Library/Frameworks/CydiaSubstrate.framework" \
      "$jailed/module/lib/CydiaSubstrate_0.9.6301.framework"
    /usr/bin/plutil -convert binary1 \
      "$jailed/module/lib/CydiaSubstrate_0.9.6301.framework/Info.plist" || true
    rm -rf \
      "$jailed/module/lib/CydiaSubstrate_0.9.6301.framework/Libraries" \
      "$jailed/module/lib/CydiaSubstrate_0.9.6301.framework/Commands"
    mkdir -p "$THEOS/mod/jailed"
    cp -a "$jailed/module/"* "$THEOS/mod/jailed/"
    mv "$THEOS/mod/jailed/lib/CydiaSubstrate_0.9.6301.framework" \
      "$THEOS/mod/jailed/lib/CydiaSubstrate.framework"

    if [[ -z "''${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
      export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    fi

    export PATH="$PATH:/usr/bin:/bin:/usr/sbin:/sbin"
    unset CC CXX NIX_CFLAGS_COMPILE NIX_LDFLAGS || true

    # Unpack decrypted YouTube IPA → Payload/YouTube.app
    cp -f ${youtubeIpa} YouTube.ipa
    unzip -q YouTube.ipa
    if [[ ! -d Payload/YouTube.app ]]; then
      echo "expected Payload/YouTube.app in decrypted IPA" >&2
      exit 1
    fi

    make package \
      DEBUG=0 \
      FINALPACKAGE=1 \
      THEOS_PACKAGE_SCHEME=rootless \
      IPA=Payload/YouTube.app \
      SDK_VERSION=${sdkVersion} \
      YOUTUBE_VERSION=${youtubeVersion} \
      UYOU_VERSION=${uyouVersion} \
      YTUHD_ENABLED=0 \
      SPONSORBLOCK_ENABLED=0

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    shopt -s nullglob
    ipas=(packages/*.ipa)
    if [[ ''${#ipas[@]} -eq 0 ]]; then
      echo "no .ipa produced under packages/" >&2
      exit 1
    fi
    mv "''${ipas[@]}" "$out/"
    primary=$(cd "$out" && ls *.ipa | head -n1)
    ln -s "$primary" "$out/uyouenhanced.ipa"
    runHook postInstall
  '';

  meta = {
    description = "uYouEnhanced — sideloadable YouTube IPA (Theos jailed)";
    homepage = "https://github.com/arichornlover/uYouEnhanced";
    license = lib.licenses.unfree;
    platforms = lib.platforms.darwin;
  };
}
