{
  mk-apk-package,
  lib,
  stdenv,
  fetchFromGitHub,
  androidSdkBuilder,
  gradle_9_4_1,
  jdk17_headless,
  writableTmpDirAsHomeHook,
  autoreconfHook,
  pkg-config,
  python3,
  fetchurl,
  unzip,
  pkgsPatched,
}:
let
  # Online source
  online-src = fetchFromGitHub {
    owner = "CollaboraOnline";
    repo = "online";
    rev = "2e18fe10a0045ac445d32a345ac6f5b7cd5298f6"; # distro/collabora/co-25.04-mobile
    hash = "sha256-w93lApxFslxHRucbp83XtK8duX9wEhTr5w9Ld9J8Ze8=";
  };

  # Core binaries from snapshot APK
  core-bin = stdenv.mkDerivation {
    pname = "collabora-office-core-bin-arm64";
    version = "2026-03-26";
    src = fetchurl {
      url = "https://www.collaboraoffice.com/downloads/Collabora-Office-Android-Snapshot/collabora-office-mobile-25.04-snapshot-arm64-v8a-2026-03-26.apk";
      hash = "sha256-Zl0nMQyghJi8ACwtkTTou7Jv1shKmhenDwUXFSH97/k=";
    };
    nativeBuildInputs = [ unzip ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/instdir/program
      unzip $src "lib/arm64-v8a/*.so" "assets/program/*" "assets/share/*" "assets/unpack/*" "assets/dist/*"
      
      mv lib/arm64-v8a/*.so $out/instdir/program/
      mv assets/program/* $out/instdir/program/
      
      mkdir -p $out/instdir/share
      cp -r assets/share/* $out/instdir/share/
      
      mkdir -p $out/android/jniLibs/arm64-v8a
      ln -s $out/instdir/program/liblo-native-code.so $out/android/jniLibs/arm64-v8a/
      ln -s $out/instdir/program/libandroidapp.so $out/android/jniLibs/arm64-v8a/
      ln -s $out/instdir/program/libc++_shared.so $out/android/jniLibs/arm64-v8a/
      
      mkdir -p $out/assets/dist
      cp -r assets/dist/* $out/assets/dist/
    '';
  };

  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-35
        s.build-tools-35-0-0
        s.ndk-28-2-13676358
      ]);

      gradle = gradle_9_4_1;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "collabora-online";
      version = "25.04.9.4";
      src = online-src;

      nativeBuildInputs = [
        autoreconfHook
        pkg-config
        python3
        python3.pkgs.lxml
        python3.pkgs.polib
        gradle
        jdk17_headless
        androidSdk
        writableTmpDirAsHomeHook
        unzip
      ];

      # Configure Online to skip native build if possible, or just provide prebuilts.
      # We'll patch the Gradle build to use our prebuilt .so files.
      postPatch = ''
        # Disable externalNativeBuild in android/lib/build.gradle
        sed -i '/externalNativeBuild {/,/}/d' android/lib/build.gradle
        
        # Add prebuilt libs to android/lib/src/main/jniLibs
        mkdir -p android/lib/src/main/jniLibs/arm64-v8a
        cp ${core-bin}/android/jniLibs/arm64-v8a/*.so android/lib/src/main/jniLibs/arm64-v8a/
        
        # Browser assets
        mkdir -p browser/dist
        cp -r ${core-bin}/assets/dist/* browser/dist/
        
        # Create appSettings.gradle and libSettings.gradle from templates
        # We'll use dummy values for hashes.
        cat > android/app/appSettings.gradle <<EOF
ext {
    liboAppName         = 'Collabora Office'
    liboVendor          = 'Collabora'
    liboInfoURL         = 'https://collaboraonline.github.io/'
    liboLauncherIcon    = '@mipmap/ic_launcher'
    liboHasBranding     = 'true'
    liboBrandingDir     = 'branding'
    liboOVersionHash    = '00000000'
    liboCoreVersionHash = '00000000'
    liboAbiSplit        = []
}
android.defaultConfig {
    applicationId 'org.collabora.app'
    versionCode 1
    versionName '25.04.9.4'
}
EOF
        cat > android/lib/libSettings.gradle <<EOF
ext {
    liboAppName         = 'Collabora Office'
    liboSrcRoot         = '/tmp/dummy'
    liboInstdir         = '${core-bin}/instdir'
    liboExampleDocument = '${core-bin}/instdir/example.odt'
    liboVersionMajor    = '25'
    liboVersionMinor    = '04'
    liboOVersionHash    = '00000000'
    liboCoreVersionHash = '00000000'
    liboApplicationId   = 'org.collabora.app'
    liboBrandingDir     = 'branding'
    liboGooglePlay      = 'false'
    liboAbiSplit        = []
}
EOF
      '';

      buildPhase = ''
        runHook preBuild
        
        # We need to run some parts of the Online build to generate necessary files
        # but we skip the actual C++ compilation.
        ./autogen.sh
        ./configure --enable-androidapp --with-lo-builddir=/tmp/dummy --with-android-sdk=${androidSdk}/share/android-sdk --with-android-ndk=${androidSdk}/share/android-sdk/ndk-bundle
        
        # Build the Java part using Gradle
        export GRADLE_USER_HOME=$HOME/.gradle
        cd android
        gradle assembleRelease
        
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out
        install -Dm644 app/build/outputs/apk/release/app-release-unsigned.apk $out/collabora-online.apk
        runHook postInstall
      '';

      meta = with lib; {
        description = "Collabora Online Android app built from source (with prebuilt core)";
        homepage = "https://github.com/CollaboraOnline/online";
        license = licenses.mpl20;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "collabora-online.apk";
  signScriptName = "sign-collabora-online";
  fdroid = {
    appId = "org.collabora.app";
    metadataYml = ''
      Categories:
        - Office
      License: MPL-2.0
      SourceCode: https://github.com/CollaboraOnline/online
      IssueTracker: https://github.com/CollaboraOnline/online/issues
      AutoName: Collabora Office
      Summary: Open source office suite based on LibreOffice
      Description: |-
        Collabora Office is a powerful office suite based on LibreOffice
        that allows you to edit documents, spreadsheets, and presentations.
        This package builds the Android wrapper from source.
    '';
  };
}
