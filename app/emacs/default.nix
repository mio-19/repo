{
  lib,
  stdenv,
  fetchFromGitHub,
  androidSdkBuilder,
  jdk17,
  autoconf,
  automake,
  m4,
  texinfo,
  ncurses,
  zip,
  which,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-34
    s.build-tools-34-0-0
    s.ndk-25-2-9519653
  ]);

  versionCode = "300200029";
  androidAbi = "arm64-v8a";
  minSdk = "29";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "emacs";
  version = "30.2";

  src = fetchFromGitHub {
    owner = "emacs-mirror";
    repo = "emacs";
    rev = "emacs-${finalAttrs.version}";
    hash = "sha256-3Lfb3HqdlXqSnwJfxe7npa4GGR9djldy8bKRpkQCdSA=";
  };

  nativeBuildInputs = [
    autoconf
    automake
    m4
    texinfo
    ncurses
    zip
    which
    jdk17
  ];

  env = {
    JAVA_HOME = "${jdk17}/lib/openjdk";
  };

  postPatch = ''
    substituteInPlace java/AndroidManifest.xml.in \
      --replace-fail 'android:versionCode="30"' 'android:versionCode="${versionCode}"'
  '';

  preConfigure = ''
    root="$PWD"

    mkdir -p .home
    export HOME="$PWD/.home"

    cd etc/e
    tic -o ../ eterm-color.ti
    cd "$root"

    ./autogen.sh
  '';

  configurePhase = ''
    runHook preConfigure

    ./configure \
      --with-android="${androidSdk}/share/android-sdk/platforms/android-34/android.jar" \
      --with-gnutls=ifavailable \
      --without-android-debug \
      --with-shared-user-id=com.termux \
      ANDROID_CC="${androidSdk}/share/android-sdk/ndk/25.2.9519653/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${minSdk}-clang" \
      SDK_BUILD_TOOLS="${androidSdk}/share/android-sdk/build-tools/34.0.0"

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    make all
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 "java/emacs-${finalAttrs.version}-${minSdk}-${androidAbi}.apk" "$out/emacs.apk"

    runHook postInstall
  '';

  meta = with lib; {
    description = "GNU Emacs for Android with the Termux shared user ID";
    homepage = "https://www.gnu.org/software/emacs/";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
})
