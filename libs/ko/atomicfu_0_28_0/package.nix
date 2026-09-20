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
  version = "0.28.0";

  src = fetchFromGitHub {
    owner = "Kotlin";
    repo = "kotlinx-atomicfu";
    tag = finalAttrs.version;
    hash = "sha256-/HgvCAVmj9e1UgI683LXoIdS/oKbCvmLTpoLmErjCDs=";
  };

  atomicfuPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/atomicfu/${finalAttrs.version}/atomicfu-${finalAttrs.version}.pom";
    hash = "sha256-yboB7z5omdQs8HDVm6OdVy/FhjvylscpqZciwGR99so=";
  };
  atomicfuModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/atomicfu/${finalAttrs.version}/atomicfu-${finalAttrs.version}.module";
    hash = "sha256-U1VoySkaPadwXEtAU16s7fhrJI31cKxSZpyQfUu4VYs=";
  };
  atomicfuJvmPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/atomicfu-jvm/${finalAttrs.version}/atomicfu-jvm-${finalAttrs.version}.pom";
    hash = "sha256-3X+tXV1LIcqdsHiHULCZe6HbaILe2G5SEvXIP8UfrOw=";
  };
  atomicfuJvmModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/atomicfu-jvm/${finalAttrs.version}/atomicfu-jvm-${finalAttrs.version}.module";
    hash = "sha256-NLYjr5wlyn8uUkBvEElcRub0EINdegWMYLo2kj1oljU=";
  };

  nativeBuildInputs = [
    jdk25_headless
    kotlin
  ];

  dontConfigure = true;
  dontUnpack = true;

  # 0.28+ adds concurrentMain (ParkingSupport). Fold it into -Xcommon-sources with
  # commonMain; the three-fragment MPP API left concurrent expects invisible to jvm.
  installPhase = ''
    runHook preInstall

    export JAVA_HOME=${jdk25_headless.passthru.home}
    tmp="$(mktemp -d)"
    root="${finalAttrs.src}/atomicfu/src"

    find "$root/commonMain" "$root/concurrentMain" -name '*.kt' | sort > "$tmp/common.txt"
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
      -opt-in=kotlinx.atomicfu.locks.ExperimentalThreadBlockingApi \
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
