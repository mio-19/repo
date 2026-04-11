{
  fetchurl,
  jdk11_headless,
  lib,
  makeWrapper,
  stdenv,
  unzip,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gradle";
  version = "5.6.4";

  src = fetchurl {
    url = "https://services.gradle.org/distributions/gradle-${finalAttrs.version}-bin.zip";
    hash = "sha256-HzBnBzBBvERVTQ7+XUAqM7w9PJPMOatoTzCFhtcyqA0=";
  };

  nativeBuildInputs = [
    makeWrapper
    unzip
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/libexec"
    cp -a . "$out/libexec/gradle"

    launcherJar="$out/libexec/gradle/lib/gradle-launcher-${finalAttrs.version}.jar"
    test -f "$launcherJar"

    makeWrapper ${jdk11_headless}/bin/java "$out/bin/gradle" \
      --set JAVA_HOME ${jdk11_headless} \
      --add-flags "-Dorg.gradle.appname=gradle" \
      --add-flags "-classpath $launcherJar" \
      --add-flags org.gradle.launcher.GradleMain

    runHook postInstall
  '';

  passthru = {
    jdk = jdk11_headless;
  };

  meta = {
    description = "Enterprise-grade build system";
    homepage = "https://gradle.org/";
    license = lib.licenses.asl20;
    mainProgram = "gradle";
    platforms = lib.platforms.linux;
    sourceProvenance = with lib.sourceTypes; [
      binaryBytecode
      binaryNativeCode
    ];
  };
})
