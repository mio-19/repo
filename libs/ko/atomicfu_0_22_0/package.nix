{
  fetchFromGitHub,
  fetchurl,
  jdk25_headless,
  kotlin,
  lib,
  libsUtils,
  stdenv,
}:

let
  inherit (libsUtils) checkMavenProvides exposeMavenProvides;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "atomicfu";
  version = "0.22.0";

  src = fetchFromGitHub {
    owner = "Kotlin";
    repo = "kotlinx-atomicfu";
    tag = finalAttrs.version;
    hash = "sha256-HLhLHboAmqW0L5+gY3DQKZZ7VvTgtYD9DuzQJ7wXsrQ=";
  };

  atomicfuPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/atomicfu/${finalAttrs.version}/atomicfu-${finalAttrs.version}.pom";
    hash = "sha256-lsP4fQNiioMRHD35NOgD134Q1hNCD3vE0wBZg4bI7zc=";
  };
  atomicfuModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/atomicfu/${finalAttrs.version}/atomicfu-${finalAttrs.version}.module";
    hash = "sha256-XIdu9+HuB90wchxDtG6tjtojzisiJg5w+TPL4AToBgc=";
  };
  atomicfuJvmPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/atomicfu-jvm/${finalAttrs.version}/atomicfu-jvm-${finalAttrs.version}.pom";
    hash = "sha256-CSM9N5NaKWh4/H6+92ECEmT64oBb+SZCAyi3y5DWelY=";
  };
  atomicfuJvmModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/atomicfu-jvm/${finalAttrs.version}/atomicfu-jvm-${finalAttrs.version}.module";
    hash = "sha256-NQcPkjzmn4fG+Q5TBXIOJwRAm2miN0SSrEW+cAde5Jo=";
  };

  nativeBuildInputs = [
    jdk25_headless
    kotlin
  ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    export JAVA_HOME=${jdk25_headless.passthru.home}
    tmp="$(mktemp -d)"
    root="${finalAttrs.src}/atomicfu/src"

    find "$root/commonMain" -name '*.kt' | sort > "$tmp/common.txt"
    find "$root/jvmMain" -name '*.kt' | sort > "$tmp/jvm.txt"
    cat "$tmp/common.txt" "$tmp/jvm.txt" > "$tmp/sources.txt"
    common_sources="$(paste -sd, "$tmp/common.txt")"

    ${kotlin}/bin/kotlinc \
      -Xmulti-platform \
      -Xcommon-sources="$common_sources" \
      -Xexpect-actual-classes \
      -language-version 2.0 \
      -api-version 2.0 \
      -Xmetadata-version=2.0.0 \
      -jvm-target 1.8 \
      -module-name atomicfu \
      -d "$tmp/atomicfu-jvm-${finalAttrs.version}.jar" \
      @"$tmp/sources.txt"

    mkdir -p "$out"
    install -Dm644 "$tmp/atomicfu-jvm-${finalAttrs.version}.jar" "$out/atomicfu-jvm-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.atomicfuPom}" "$out/atomicfu-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.atomicfuModule}" "$out/atomicfu-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.atomicfuJvmPom}" "$out/atomicfu-jvm-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.atomicfuJvmModule}" "$out/atomicfu-jvm-${finalAttrs.version}.module"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = checkMavenProvides finalAttrs;

  meta = with lib; {
    description = "AtomicFU multiplatform atomic operations library for Kotlin";
    homepage = "https://github.com/Kotlin/kotlinx-atomicfu";
    license = licenses.asl20;
    platforms = platforms.unix;
    sourceProvenance = with sourceTypes; [ fromSource ];
    mavenProvides = exposeMavenProvides finalAttrs;
    mavenProvidesInternal = {
      "org.jetbrains.kotlinx:atomicfu-jvm:${finalAttrs.version}" = {
        "atomicfu-jvm-${finalAttrs.version}.jar" = "$out/atomicfu-jvm-${finalAttrs.version}.jar";
        "atomicfu-jvm-${finalAttrs.version}.module" = "$out/atomicfu-jvm-${finalAttrs.version}.module";
        "atomicfu-jvm-${finalAttrs.version}.pom" = "$out/atomicfu-jvm-${finalAttrs.version}.pom";
      };
      "org.jetbrains.kotlinx:atomicfu:${finalAttrs.version}" = {
        "atomicfu-${finalAttrs.version}.module" = "$out/atomicfu-${finalAttrs.version}.module";
        "atomicfu-${finalAttrs.version}.pom" = "$out/atomicfu-${finalAttrs.version}.pom";
      };
    };
  };
})
