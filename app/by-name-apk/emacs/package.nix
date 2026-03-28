{
  mk-apk-package,
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
  ...
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-36-0-0
        s.ndk-25-2-9519653
      ]);

      versionCode = "310050029";
      androidAbi = "arm64-v8a";
      minSdk = "29";
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "emacs";
      version = "31.0.50";

      src = fetchFromGitHub {
        owner = "emacs-mirror";
        repo = "emacs";
        rev = "c852297037cbf5fad63dc548530491e2d9fa3b48";
        hash = "sha256-PNeXgSZ1zYVDyiIw6Wi1Kn7o0vM7VUty0+xCmkoHNAg=";
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
          --with-android="${androidSdk}/share/android-sdk/platforms/android-36/android.jar" \
          --with-gnutls=ifavailable \
          --without-android-debug \
          --with-shared-user-id=com.termux \
          ANDROID_CC="${androidSdk}/share/android-sdk/ndk/25.2.9519653/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${minSdk}-clang" \
          SDK_BUILD_TOOLS="${androidSdk}/share/android-sdk/build-tools/36.0.0"

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
        platforms = platforms.unix;
        sourceProvenance = with sourceTypes; [ fromSource ];
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "emacs.apk";
  signScriptName = "sign-emacs";
  fdroid = {
    appId = "org.gnu.emacs";
    metadataYml = ''
      Categories:
        - Development
        - Text Editor
        - Writing
      License: GPL-3.0-or-later
      WebSite: https://www.gnu.org/software/emacs/
      SourceCode: https://git.savannah.gnu.org/cgit/emacs.git/tree/
      IssueTracker: https://debbugs.gnu.org/
      Changelog: https://git.savannah.gnu.org/cgit/emacs.git/tree/etc/NEWS?h=master
      Donate: https://my.fsf.org/donate/
      AutoName: Emacs
      Summary: GNU Emacs with Termux shared user ID support
      Description: |-
        GNU Emacs is an extensible, customizable, free/libre text
        editor and Lisp environment.

        This build is compiled from source from the current Emacs 31.0.50
        development snapshot and configured with the shared user ID `com.termux`,
        so it can access the files and executables of the Termux app
        from this repo when both are installed and signed together.

        Install Termux first, then install this Emacs build.
    '';
  };
}
