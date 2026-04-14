{
  fetchFromGitHub,
  fetchurl,
  jdk25_headless,
  kotlin,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kotlin-result";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "michaelbull";
    repo = "kotlin-result";
    tag = finalAttrs.version;
    hash = "sha256-sCPA2yl8rieyss08PKeNDldmnSas1tOJmP5HkF8iaus=";
  };

  kotlinResultModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/michael-bull/kotlin-result/kotlin-result/2.1.0/kotlin-result-2.1.0.module";
    hash = "sha256-DcA9FvZpwVpbXQtL9XNtpsSV84fkbwF/vY3gl+rpq30=";
  };
  kotlinResultPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/michael-bull/kotlin-result/kotlin-result/2.1.0/kotlin-result-2.1.0.pom";
    hash = "sha256-9B8Y8JwewBYxjETIDipRdtGyWwmA6YFD0ZyZUZfMuP0=";
  };
  kotlinResultJvmModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/michael-bull/kotlin-result/kotlin-result-jvm/2.1.0/kotlin-result-jvm-2.1.0.module";
    hash = "sha256-bXrjEbDkoErZXHj39raF6ViARuE1M3/DTlqepNPwRls=";
  };
  kotlinResultJvmPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/michael-bull/kotlin-result/kotlin-result-jvm/2.1.0/kotlin-result-jvm-2.1.0.pom";
    hash = "sha256-XXh2ya3NvQHae2k5UIPIq/wVLPnMTHAkmauNVZywJw4=";
  };

  nativeBuildInputs = [
    jdk25_headless
    kotlin
  ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    export JAVA_HOME=${jdk25_headless}
    tmp="$(mktemp -d)"

    cd "$tmp"

    find "${finalAttrs.src}/kotlin-result/src/commonMain/kotlin" -name '*.kt' | sort > common-sources.txt
    find "${finalAttrs.src}/kotlin-result/src/jvmMain/kotlin" -name '*.kt' | sort > jvm-sources.txt
    cat common-sources.txt jvm-sources.txt > sources.txt
    common_sources="$(paste -sd, common-sources.txt)"
    ${kotlin}/bin/kotlinc \
      -Xmulti-platform \
      -Xcommon-sources="$common_sources" \
      -jvm-target 1.8 \
      -opt-in=kotlin.contracts.ExperimentalContracts \
      -opt-in=com.github.michaelbull.result.annotation.UnsafeResultValueAccess \
      -opt-in=com.github.michaelbull.result.annotation.UnsafeResultErrorAccess \
      -module-name kotlin-result-jvm \
      -d "$tmp/kotlin-result-jvm-${finalAttrs.version}.jar" \
      @sources.txt

    mkdir -p "$out"
    install -Dm644 "$tmp/kotlin-result-jvm-${finalAttrs.version}.jar" "$out/kotlin-result-jvm-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.kotlinResultModule}" "$out/kotlin-result-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.kotlinResultPom}" "$out/kotlin-result-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.kotlinResultJvmModule}" "$out/kotlin-result-jvm-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.kotlinResultJvmPom}" "$out/kotlin-result-jvm-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Multiplatform Result monad for Kotlin";
    homepage = "https://github.com/michaelbull/kotlin-result";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
