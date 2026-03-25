{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchzip,
  runCommand,
  androidSdkBuilder,
  gradle-packages,
  jdk17,
  apksigner,
  writableTmpDirAsHomeHook,
  bison,
  python3,
  gcc,
}:
let
  rev = "3376f0ed5f5c7cf4ba960df218a00c6cc053ffb7";
  shortRev = builtins.substring 0 7 rev;
  version = "unstable-2026-02-18";

  rootSrc = fetchFromGitHub {
    owner = "termux";
    repo = "termux-x11";
    inherit rev;
    hash = "sha256-kT1/qawEvFswUjO4VGmSLUTyA3V4Bl6IaeTMZoGcauU=";
  };

  bzip2Src = fetchzip {
    url = "https://gitlab.com/bzip2/bzip2/-/archive/66c46b8c9436613fd81bc5d03f63a61933a4dcc3/bzip2-66c46b8c9436613fd81bc5d03f63a61933a4dcc3.tar.gz";
    hash = "sha256-m3AdOsVGpeG6gmp2q5tmqNtd3ZTUCQl0feLIleuGkOA=";
  };

  libepoxySrc = fetchzip {
    url = "https://github.com/anholt/libepoxy/archive/1b6d7db184bb1a0d9af0e200e06a0331028eaaae.tar.gz";
    hash = "sha256-so6HfH12qn+wf1jkd2ny8eVUiLjHRaXvPW1WtTMwtxQ=";
  };

  libfontencSrc = fetchzip {
    url = "https://gitlab.freedesktop.org/xorg/lib/libfontenc/-/archive/780d1f6f192a331de7b298a96e23ebc44d2a884b/libfontenc-780d1f6f192a331de7b298a96e23ebc44d2a884b.tar.gz";
    hash = "sha256-upChhVST27M5h2KKCcb5bN5MZrgIxgDthrwHH96ZNwc=";
  };

  libtirpcSrc = fetchzip {
    url = "https://github.com/alisw/libtirpc/archive/5ca4ca92f629d9d83e83544b9239abaaacf0a527.tar.gz";
    hash = "sha256-USqQ8qx1CEUGMLKvTxQOTTrH77HmaLOdS9gZ7ohuhO8=";
  };

  libx11Src = fetchzip {
    url = "https://gitlab.freedesktop.org/xorg/lib/libx11/-/archive/59917d28a3c41ad22d6fc52e323cafe2cdd596d5/libx11-59917d28a3c41ad22d6fc52e323cafe2cdd596d5.tar.gz";
    hash = "sha256-6tkeyzR8c9/ZMnbeesddtbVV33UZAEEkJ/99RIoTzVw=";
  };

  libxauSrc = fetchzip {
    url = "https://gitlab.freedesktop.org/xorg/lib/libxau/-/archive/a9c65683e68b3a4349afee5d7673b393fb924d2e/libxau-a9c65683e68b3a4349afee5d7673b393fb924d2e.tar.gz";
    hash = "sha256-zSj0btY9hz/OWTpzqVP+cHWDqKrBL4UkexOwp8B+OXU=";
  };

  libxcvtSrc = fetchzip {
    url = "https://gitlab.freedesktop.org/xorg/lib/libxcvt/-/archive/bfca4a27f9e8bada2469573653da75536c578946/libxcvt-bfca4a27f9e8bada2469573653da75536c578946.tar.gz";
    hash = "sha256-le2TVWVN2cA4HwZ1h/T+mFPA7/bH1CIvSycKIGbNmVs=";
  };

  libxdmcpSrc = fetchzip {
    url = "https://gitlab.freedesktop.org/xorg/lib/libxdmcp/-/archive/cd27f35c08cd8a7b14cef31d3edc021e638aab7f/libxdmcp-cd27f35c08cd8a7b14cef31d3edc021e638aab7f.tar.gz";
    hash = "sha256-Mapm1oH4pZL9juBNIXErC4bmi85Oqaoj+mnCSsN3jvk=";
  };

  libxfontSrc = fetchzip {
    url = "https://gitlab.freedesktop.org/xorg/lib/libxfont/-/archive/67520db20c6cc37927ae3a212f357e2dd26143f5/libxfont-67520db20c6cc37927ae3a212f357e2dd26143f5.tar.gz";
    hash = "sha256-JcjuAnjukzsSxmjylVmrhADksAY8k97Nvgh+Cisq9zk=";
  };

  libxkbfileSrc = fetchzip {
    url = "https://gitlab.freedesktop.org/xorg/lib/libxkbfile/-/archive/39a5f8e67615f443e76146769d5f5f9abc5ebd2f/libxkbfile-39a5f8e67615f443e76146769d5f5f9abc5ebd2f.tar.gz";
    hash = "sha256-9CeKYvB/7z2JMHit46rXgTHiiTW9o3KFf2TPhNeisZ0=";
  };

  libxshmfenceSrc = fetchzip {
    url = "https://gitlab.freedesktop.org/xorg/lib/libxshmfence/-/archive/c8acc32ffec83765c8388ba75f172bcd7892c3f9/libxshmfence-c8acc32ffec83765c8388ba75f172bcd7892c3f9.tar.gz";
    hash = "sha256-RndmQz489tnkWHAII8stmsvBH961t2CFSyra8I2BVq4=";
  };

  libxtransSrc = fetchzip {
    url = "https://gitlab.freedesktop.org/xorg/lib/libxtrans/-/archive/cf05ba4a10c90da2c63805a5375e983b174e28b0/libxtrans-cf05ba4a10c90da2c63805a5375e983b174e28b0.tar.gz";
    hash = "sha256-+V7qrITaYqqC6wFo28jhM3oxpACk1GoEYgK0FRRQJqY=";
  };

  pixmanSrc = fetchzip {
    url = "https://gitlab.freedesktop.org/pixman/pixman/-/archive/9cc163c9da0fb4da430641715313d95a6ec466d9/pixman-9cc163c9da0fb4da430641715313d95a6ec466d9.tar.gz";
    hash = "sha256-SiXzRtCuAkbg4LBFc3USTRwj9qsAtLyfzaDMed8h7Cc=";
  };

  xkbcompSrc = fetchzip {
    url = "https://gitlab.freedesktop.org/xorg/app/xkbcomp/-/archive/e26102f28f08e5432b1ad44bbaef7f32aff199f6/xkbcomp-e26102f28f08e5432b1ad44bbaef7f32aff199f6.tar.gz";
    hash = "sha256-CrQwo4CsmKu7TDgxCmxpFdfV7q4Ukeo1QhnVQpnJ9ug=";
  };

  xorgprotoSrc = fetchzip {
    url = "https://gitlab.freedesktop.org/xorg/proto/xorgproto/-/archive/81931cc0fd4761b42603f7da7d4f50fc282cecc6/xorgproto-81931cc0fd4761b42603f7da7d4f50fc282cecc6.tar.gz";
    hash = "sha256-qE8iVkkGBrbRDRBPruedESIEAaeooyxXtzWK3iwXgws=";
  };

  xserverSrc = fetchzip {
    url = "https://gitlab.freedesktop.org/xorg/xserver/-/archive/2403cd5352b2a60d045b7f53c3c30002eb877f57/xserver-2403cd5352b2a60d045b7f53c3c30002eb877f57.tar.gz";
    hash = "sha256-IZvwTVnzQamnk4W+OzY3ovHLs9Z0vhPAUXDQkeFwFew=";
  };

  src = runCommand "termux-x11-src-${shortRev}" { } ''
    cp -R ${rootSrc} "$out"
    chmod -R u+w "$out"

    rm -rf \
      "$out/app/src/main/cpp/bzip2" \
      "$out/app/src/main/cpp/libepoxy" \
      "$out/app/src/main/cpp/libfontenc" \
      "$out/app/src/main/cpp/libtirpc" \
      "$out/app/src/main/cpp/libx11" \
      "$out/app/src/main/cpp/libxau" \
      "$out/app/src/main/cpp/libxcvt" \
      "$out/app/src/main/cpp/libxdmcp" \
      "$out/app/src/main/cpp/libxfont" \
      "$out/app/src/main/cpp/libxkbfile" \
      "$out/app/src/main/cpp/libxshmfence" \
      "$out/app/src/main/cpp/libxtrans" \
      "$out/app/src/main/cpp/pixman" \
      "$out/app/src/main/cpp/xkbcomp" \
      "$out/app/src/main/cpp/xorgproto" \
      "$out/app/src/main/cpp/xserver"

    cp -R ${bzip2Src} "$out/app/src/main/cpp/bzip2"
    cp -R ${libepoxySrc} "$out/app/src/main/cpp/libepoxy"
    cp -R ${libfontencSrc} "$out/app/src/main/cpp/libfontenc"
    cp -R ${libtirpcSrc} "$out/app/src/main/cpp/libtirpc"
    cp -R ${libx11Src} "$out/app/src/main/cpp/libx11"
    cp -R ${libxauSrc} "$out/app/src/main/cpp/libxau"
    cp -R ${libxcvtSrc} "$out/app/src/main/cpp/libxcvt"
    cp -R ${libxdmcpSrc} "$out/app/src/main/cpp/libxdmcp"
    cp -R ${libxfontSrc} "$out/app/src/main/cpp/libxfont"
    cp -R ${libxkbfileSrc} "$out/app/src/main/cpp/libxkbfile"
    cp -R ${libxshmfenceSrc} "$out/app/src/main/cpp/libxshmfence"
    cp -R ${libxtransSrc} "$out/app/src/main/cpp/libxtrans"
    cp -R ${pixmanSrc} "$out/app/src/main/cpp/pixman"
    cp -R ${xkbcompSrc} "$out/app/src/main/cpp/xkbcomp"
    cp -R ${xorgprotoSrc} "$out/app/src/main/cpp/xorgproto"
    cp -R ${xserverSrc} "$out/app/src/main/cpp/xserver"
  '';

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-34
    s.build-tools-34-0-0
    s.build-tools-36-0-0
    s.ndk-29-0-14206865
    s.cmake-3-22-1
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "9.3.1";
      hash = "sha256-smbV/2uQ6tptw7IMsJDjcxMC5VOifF0+TfHw12vq/wY=";
      defaultJava = jdk17;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "termux-x11";
  inherit version;
  inherit src;

  gradleBuildTask = ":app:assembleDebug";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = "termux-x11_deps.json";
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk17
    apksigner
    writableTmpDirAsHomeHook
    bison
    python3
    gcc
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk17}" else "${jdk17}/lib/openjdk";
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/29.0.14206865";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
    CURRENT_COMMIT = rev;
  };

  postPatch = ''
    substituteInPlace app/build.gradle \
      --replace-fail "    compileSdkVersion 34
" "    compileSdkVersion 34
    ndkVersion \"29.0.14206865\"
"

    substituteInPlace app/build.gradle \
      --replace-fail "def commit= 'git rev-parse --verify --short HEAD'.execute().text.trim()" "def commit = System.getenv('TERMUX_X11_GIT_SHORT_COMMIT') ?: '${shortRev}'" \
      --replace-fail '-''${commit.length()==1?"nongit":commit}-''${(new Date()).format("dd.MM.yy")}' '+git.''${commit}' \
      --replace-fail "\"\\\"\" + (\"git rev-parse HEAD\\n\".execute().getText().trim() ?: (System.getenv('CURRENT_COMMIT') ?: \"NO_COMMIT\")) + \"\\\"\"" "\"\\\"\" + (System.getenv('CURRENT_COMMIT') ?: \"${rev}\") + \"\\\"\""

    substituteInPlace shell-loader/build.gradle \
      --replace-fail "\"\\\"\" + (\"git rev-parse HEAD\\n\".execute().getText().trim() ?: (System.getenv('CURRENT_COMMIT') ?: \"NO_COMMIT\")) + \"\\\"\"" "\"\\\"\" + (System.getenv('CURRENT_COMMIT') ?: \"${rev}\") + \"\\\"\""

    substituteInPlace app/src/main/cpp/recipes/xkbcomp.cmake \
      --replace-fail 'COMMAND "/usr/bin/gcc"' 'COMMAND "${gcc}/bin/gcc"'
  '';

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    "-Dorg.gradle.jvmargs=-Xmx4096m"
  ];

  TERMUX_X11_GIT_SHORT_COMMIT = shortRev;

  installPhase = ''
    runHook preInstall
    install -Dm644 app/build/outputs/apk/debug/app-universal-debug.apk "$out/termux-x11.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Termux X11 server add-on app built from source";
    homepage = "https://github.com/termux/termux-x11";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
})
