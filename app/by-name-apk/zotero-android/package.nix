{ callPackage, ... }:
let
  appPackage = callPackage (
    {
      lib,
      jdk17_headless,
      gradle-packages,
      stdenv,
      fetchFromGitHub,
      apksigner,
      writableTmpDirAsHomeHook,
      androidSdkBuilder,
      git,
      fetchpatch,
    }:
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-35
        s.build-tools-33-0-1
        s.build-tools-35-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "9.2.1";
          hash = "sha256-cvRMn468sa9Dg49F7lxKqcVESJizRoqz9K97YHbFvD8=";
          defaultJava = jdk17_headless;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "zotero-android";
      version = "1.0.0-231";

      src = fetchFromGitHub {
        owner = "zotero";
        repo = "zotero-android";
        tag = finalAttrs.version;
        hash = "sha256-E/urUZoKLpXtL/HzI17w0Cs4ny5qjwfxzfQm8C5l5ZE=";
      };

      patches = [
        (fetchpatch {
          name = "Add a button to fetch all";
          url = "https://github.com/zotero/zotero-android/pull/291.patch";
          hash = "sha256-gdDpOwy5PUeDksqxz0B1DMHSSgH3nyj0vdQGSd0oNG4=";
        })
      ];

      gradleBuildTask = ":app:assembleInternalRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./zotero_android_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk17_headless
        apksigner
        writableTmpDirAsHomeHook
        git
      ];

      env = {
        JAVA_HOME = jdk17_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
        REALM_DISABLE_ANALYTICS = "true";
      };

      prePatch = ''
        substituteInPlace app/build.gradle.kts \
          --replace-fail 'import com.github.triplet.gradle.androidpublisher.ResolutionStrategy' "" \
          --replace-fail '    id("com.github.triplet.play") version "3.12.1"' "" \
          --replace-fail $'play {\n    track.set("internal")\n    defaultToAppBundles.set(true)\n    resolutionStrategy.set(ResolutionStrategy.AUTO)\n}\n' "" \
          --replace-fail '            signingConfig = signingConfigs.getAt("release")' ""
        echo "s z F t l F P 2 1 b 9 _ _ l Q 1 l Q L v T X M w z G z a q s N 4 5 0 I i 3 S w c B F M 1 X g M D y u 4 i n Q h 9 0 A M p T B o 2 9 4 U y y - u z t S H g Q t 9 9 Y J X 6 T 3 I E R l G k y z j I t U C Q 2 _ 4 d Q 3 u H _ l Z b U Z x 5 3 d 2 i 6 o a I u l h 3 4 s 7 Y v Q q k v 4 G B T t J V X x 0 H V 1 f r 3 Y f q t N m y A P _ R - q p w 8 u - 5 L X S y 7 G 9 P y T B C U c g 4 P H h P F v I G - G P r b c 9 O v s b W R H B - - p C b 2 S 9 F X X 4 Q 5 y V R Q L Z i j E Q l P 8 l v _ n P 3 I y w x - H 5 3 5 D y f F I s u y c u t w 8 s H f z 1 M k 1 U R r e o Y 9 8 R m C e 5 J z 8 P T a s 4 B - Z o a B 9 L g S a h D 8 z o S x w I 4 r J I S P V P 3 y w G y P X x I y T G 1 A Z B n E C W l d E b E j 4 A z T l C v 0 4 b D 4 y s 6 y z t u r U t W j q L x r i 5 p g g R W w 9 W E O i I L H m 4 Q D Z T n M w F D s 8 q G A u R Q a h Q p I j 3 E l v K m T n 0 Z z V H K V l l k 4 J T - F y s M - F 8 T p 2 Z l l M n F x w m i n t m d W G h l G M 3 T a _ p M 6 A c 7 a _ 5 K S X e K u p j A u P G p _ L m 5 I C u g Z Q V 1 9 Z 4 a 5 c N j x n 3 O R D y h f w b M r Y f Y I J T b J O z s l M A g O b u S 5 y 3 5 o w P j h N K 3 W J i g 0 t Y 5 g F i V P 6 O E Z n I d 2 G p w m T q 4 K F m z M _ p X Y E O u 6 9 S D a N D p H _ s w M v 5 L s M J o I J L t z h a I F h y g L j U 4 t I f W " > pspdfkit-key.txt
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        install -Dm644 \
          app/build/outputs/apk/internal/release/app-internal-release-unsigned.apk \
          "$out/zotero-android.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Zotero Android beta build from source (unsigned)";
        homepage = "https://github.com/zotero/zotero-android";
        license = licenses.agpl3Only;
        platforms = platforms.unix;
      };
    })
  ) { };
in
callPackage ../../by-name/mk-apk-package/package.nix {
  inherit appPackage;
  mainApk = "zotero-android.apk";
  signScriptName = "sign-zotero-android";
  fdroid = {
    appId = "org.zotero.android";
    metadataYml = ''
      Categories:
        - Reading
        - Science & Education
      License: AGPL-3.0-only
      WebSite: https://www.zotero.org/
      SourceCode: https://github.com/zotero/zotero-android
      IssueTracker: https://github.com/zotero/zotero-android/issues
      Changelog: https://github.com/zotero/zotero-android/releases
      AutoName: Zotero
      Summary: Sync and manage your Zotero library on Android
      Description: |-
        Zotero is a research assistant for collecting, organizing,
        annotating, and syncing references, PDFs, and notes.

        This package is built from source from the latest upstream tag.
    '';
  };
}
