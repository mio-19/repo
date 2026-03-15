{
  pkgs,
  androidSdk,
  gradle2nixBuilders,
}:

gradle2nixBuilders.buildGradlePackage {
  pname = "meshtastic";
  version = "2.7.13";

  src = pkgs.fetchFromGitHub {
    owner = "meshtastic";
    repo = "Meshtastic-Android";
    rev = "v2.7.13";
    hash = "sha256-bktrjU/KgUeh4eLPfQM3No1oK5YOo3bjRHRk+qGg4X8=";
    fetchSubmodules = true;
  };


  lockFile = ./gradle.lock;

  buildJdk = pkgs.jdk21;

  nativeBuildInputs = [
    androidSdk
    pkgs.jdk17
    pkgs.jdk21
  ];

  patches = [
    # Remove foojay JDK auto-provisioner plugin and toolchainManagement block
    # — prevents network access in sandbox (follows FDroid 2.7.10 prebuild).
    # Must be first: later patches assume foojay line is already gone.
    ./remove-foojay.patch
    # Remove develocity build-scan plugin (not needed for building, causes class-load errors)
    ./remove-develocity.patch
    # Pin kotlin-dsl to 6.4.2 in build-logic (5.2.0 is bundled with Gradle 9.3.1
    # and not published to Maven; gradle2nix cannot capture it)
    ./pin-kotlin-dsl.patch
    # Remove firebase plugin declarations from root build.gradle.kts
    # (alias …firebase… apply false — unneeded for fdroid flavor)
    ./remove-firebase-root.patch
    # Remove compileOnly(libs.firebase.crashlytics.gradlePlugin) from build-logic
    ./remove-firebase-convention.patch
    # Remove firebase-crashlytics apply() call and plugins.withId block from
    # AnalyticsConventionPlugin.kt so it compiles and runs cleanly without Firebase
    ./remove-firebase-analytics-plugin.patch
  ];

  postPatch = ''
    # Point AGP at the Nix-provided Android SDK
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties

    # Disable JDK auto-download; provide both JDK 17 (build-logic) and JDK 21 (app)
    echo "org.gradle.java.installations.auto-download=false" >> gradle.properties
    echo "org.gradle.java.installations.paths=${pkgs.jdk17},${pkgs.jdk21}" >> gradle.properties
  '';

  dontUseCmakeConfigure = true;
  dontUseNinjaBuild = true;

  env = {
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
  };

  gradleBuildFlagsArray = [ ":app:assembleFdroidRelease" ];

  installPhase = ''
    runHook preInstall
    install -Dm644 app/build/outputs/apk/fdroid/release/app-fdroid-release-unsigned.apk \
      "$out/meshtastic.apk"
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Meshtastic Android app (F-Droid flavor, unsigned)";
    homepage = "https://meshtastic.org";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
