{
  mk-apk-package,
  lib,
  jdk21_headless,
  stdenv,
  fetchurl,
  unzip,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  gradle_8_13,
  fetchFromGitHub,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-34
        s.build-tools-34-0-0
        s.ndk-27-3-13750724
      ]);

      gradle = gradle_8_13;

      # https://github.com/AngelAuraMC/angelauramc-openjdk-build/actions
      jre8Pojav = fetchurl {
        name = "jre8-pojav.zip";
        url = "https://web.archive.org/web/20260324115718/https://productionresultssa10.blob.core.windows.net/actions-results/0e976468-66eb-48c5-ab72-9fcea72b1aa3/workflow-job-run-cc794f90-74e0-5bcd-904b-e0ffd336b256/artifacts/557d0d369aa1ac3c31cbb7b7cf155ecc92686aa06b1541bb8645b002b7cf7541.zip?rscd=attachment%3B+filename%3D%22jre8-pojav.zip%22&rsct=application%2Fzip&se=2026-03-24T12%3A07%3A05Z&sig=IV6QzxFyOk6nSVI5ci5frSp3knhRuuQz0Z9tUl1RQRA%3D&ske=2026-03-24T15%3A49%3A52Z&skoid=ca7593d4-ee42-46cd-af88-8b886a2f84eb&sks=b&skt=2026-03-24T11%3A49%3A52Z&sktid=398a6654-997b-47e9-b12b-9515b896b4de&skv=2025-11-05&sp=r&spr=https&sr=b&st=2026-03-24T11%3A57%3A00Z&sv=2025-11-05";
        hash = "sha256-Ryn1rWd2GkdSau6emOnzMkrD6HhqutCA2Pa+yWlQGY0=";
      };

      jre17Pojav = fetchurl {
        name = "jre17-pojav.zip";
        url = "https://web.archive.org/web/20260328022223if_/https://productionresultssa1.blob.core.windows.net/actions-results/14cf2225-a217-44e1-964f-b68eee9450ba/workflow-job-run-68da9bab-66f4-5a5b-8393-e7b46f104935/artifacts/c428f5f9b02e4a2ede0f97efdfa5f3ce28531f3cf5cef779324c026e24bd79a2.zip?rscd=attachment%3B+filename%3D%22jre17-pojav.zip%22&rsct=application%2Fzip&se=2026-03-28T02%3A32%3A09Z&sig=4Dbuy9%2FSx%2BYLmFIhb6REbi4zM0c43NG%2F4sWed%2BnYdiE%3D&ske=2026-03-28T04%3A11%3A45Z&skoid=ca7593d4-ee42-46cd-af88-8b886a2f84eb&sks=b&skt=2026-03-28T00%3A11%3A45Z&sktid=398a6654-997b-47e9-b12b-9515b896b4de&skv=2025-11-05&sp=r&spr=https&sr=b&st=2026-03-28T02%3A22%3A04Z&sv=2025-11-05";
        hash = "sha256-v3JD1X+xWZ/jAa2OMdtdih6sRBqWP/zTf8ITnPTLNP8=";
      };

      jre21Pojav = fetchurl {
        name = "jre21-pojav.zip";
        url = "https://web.archive.org/web/20260324115734/https://productionresultssa1.blob.core.windows.net/actions-results/14cf2225-a217-44e1-964f-b68eee9450ba/workflow-job-run-1135f488-ae8a-5b6d-b141-314c13711dad/artifacts/01a97264a546e399b747a54ac611e7fe51d9c8f3493ce2f03da6c99ab7244225.zip?rscd=attachment%3B+filename%3D%22jre21-pojav.zip%22&rsct=application%2Fzip&se=2026-03-24T12%3A06%3A33Z&sig=FT2dU9rSafiLUVLlHJFrQe%2FakNdrNUzM43%2BqqaoeOhM%3D&ske=2026-03-24T12%3A59%3A26Z&skoid=ca7593d4-ee42-46cd-af88-8b886a2f84eb&sks=b&skt=2026-03-24T08%3A59%3A26Z&sktid=398a6654-997b-47e9-b12b-9515b896b4de&skv=2025-11-05&sp=r&spr=https&sr=b&st=2026-03-24T11%3A56%3A28Z&sv=2025-11-05";
        hash = "sha256-JjxMszhQa6k06GeTj89rqQzxJs5fdXkMSlO2f84ZJYA=";
      };

      jre25Multiarch = fetchurl {
        name = "jre25-multiarch.zip";
        url = "https://web.archive.org/web/20260324115849/https://productionresultssa2.blob.core.windows.net/actions-results/4575f23a-e12b-4f5e-b082-da47656bc98b/workflow-job-run-bc384a9e-1d02-5506-ac25-e6ac0295ed12/artifacts/71e2c6658755510162ae6d9ed3c6ffea5a91fa2dbbdf9c0f1575ec437a5cce42.zip?rscd=attachment%3B+filename%3D%22jre25-multiarch.zip%22&rsct=application%2Fzip&se=2026-03-24T12%3A08%3A41Z&sig=7%2BFuA8VlDyxvdjxFdqsEm%2FeNjY0qn63qg%2FsM09M3Jpw%3D&ske=2026-03-24T15%3A58%3A11Z&skoid=ca7593d4-ee42-46cd-af88-8b886a2f84eb&sks=b&skt=2026-03-24T11%3A58%3A11Z&sktid=398a6654-997b-47e9-b12b-9515b896b4de&skv=2025-11-05&sp=r&spr=https&sr=b&st=2026-03-24T11%3A58%3A36Z&sv=2025-11-05";
        hash = "sha256-oYk6/5e6SJfvZYvEVN4hC2D4mi21LHQys25ewEbUalM=";
      };
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "amethyst";
      # go to https://github.com/AngelAuraMC/Amethyst-Android/releases/latest to check the latest version. they have git tags that seem newer in number but very old.
      version = "1.1.2";

      src = fetchFromGitHub {
        owner = "AngelAuraMC";
        repo = "Amethyst-Android";
        tag = finalAttrs.version;
        hash = "sha256-E70dxAn3oN/dme6phvmM6+xtvJ2T2vAeuXiws+qWrp8=";
      };

      gradleBuildTask = ":app_pojavlauncher:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./amethyst_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21_headless
        unzip
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
        AMETHYST_VERSION_NAME = finalAttrs.version;
        CURSEFORGE_API_KEY = "DUMMY";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        cat > local.properties <<EOF
        sdk.dir=${androidSdk}/share/android-sdk
        ndk.dir=${androidSdk}/share/android-sdk/ndk/27.3.13750724
        EOF
      '';

      postPatch = ''
        unpack_runtime_zip() {
          local archive="$1"
          local destination="$2"
          mkdir -p "$destination"
          unzip -q "$archive" -d "$destination"
        }

        unpack_runtime_zip ${jre8Pojav} app_pojavlauncher/src/main/assets/components/jre
        unpack_runtime_zip ${jre17Pojav} app_pojavlauncher/src/main/assets/components/jre-new
        unpack_runtime_zip ${jre21Pojav} app_pojavlauncher/src/main/assets/components/jre-21
        unpack_runtime_zip ${jre25Multiarch} app_pojavlauncher/src/main/assets/components/jre-25

        substituteInPlace app_pojavlauncher/build.gradle \
          --replace-fail '        abortOnError false' $'        abortOnError false\n        checkReleaseBuilds false' \
          --replace-fail '        versionName getVersionName()' '        versionName System.getenv("AMETHYST_VERSION_NAME") ?: getVersionName()' \
          --replace-fail '            signingConfig signingConfigs.customRelease' ""
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="$(echo app_pojavlauncher/build/outputs/apk/release/*.apk)"
        install -Dm644 "$apk_path" "$out/amethyst.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Amethyst Android Minecraft launcher";
        homepage = "https://github.com/AngelAuraMC/Amethyst-Android";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "amethyst.apk";
  signScriptName = "sign-amethyst";
  fdroid = {
    appId = "org.angelauramc.amethyst";
    metadataYml = ''
      Categories:
        - Games
      License: GPL-3.0-only
      SourceCode: https://github.com/AngelAuraMC/Amethyst-Android
      IssueTracker: https://github.com/AngelAuraMC/Amethyst-Android/issues
      Changelog: https://github.com/AngelAuraMC/Amethyst-Android/commits/v3_openjdk
      AutoName: Amethyst
      Summary: Android launcher for Minecraft Java Edition
      Description: |-
        Amethyst is an Android launcher for Minecraft Java Edition based
        on the PojavLauncher codebase with an updated native stack and
        bundled runtime components.
        This package is built from source from the latest `v3_openjdk`
        branch commit pinned in this repo.
    '';
  };
}
