{
  fetchFromGitHub,
  fetchurl,
  jdk25_headless,
  kotlin,
  kotlin_result_2_1_0,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kotlin-retry";
  version = "2.0.2";

  src = fetchFromGitHub {
    owner = "michaelbull";
    repo = "kotlin-retry";
    tag = finalAttrs.version;
    hash = "sha256-FFxOXiOs0MZKYhnR74xsnz5NFR5ktTFFhlxtUrrIjlY=";
  };

  coroutinesCoreJvm = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-coroutines-core-jvm/1.10.2/kotlinx-coroutines-core-jvm-1.10.2.jar";
    hash = "sha256-XKF1s43zMf1kFVs1zYyuElH6nuNpcJs21C4KKIzM4/0=";
  };

  kotlinRetryModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/michael-bull/kotlin-retry/kotlin-retry/2.0.2/kotlin-retry-2.0.2.module";
    hash = "sha256-lAKHA0PzbWUiICFjoXUTy6aePJUJRDXlP09Oeuypkzo=";
  };
  kotlinRetryPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/michael-bull/kotlin-retry/kotlin-retry/2.0.2/kotlin-retry-2.0.2.pom";
    hash = "sha256-RJm74GyRKyCyo7sGPgHxeic5RgA2znAUB/UgPwgY9WQ=";
  };
  kotlinRetryJvmModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/michael-bull/kotlin-retry/kotlin-retry-jvm/2.0.2/kotlin-retry-jvm-2.0.2.module";
    hash = "sha256-xyNg7KAgM0fnZ02zX/CyvPvqVwQWyw7W/ysYmJvXKZY=";
  };
  kotlinRetryJvmPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/michael-bull/kotlin-retry/kotlin-retry-jvm/2.0.2/kotlin-retry-jvm-2.0.2.pom";
    hash = "sha256-CuL8fq/pD8lfEKPyKzdWiVrzIWzq9Q0TAfWGfYD73Z8=";
  };
  kotlinRetryResultModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/michael-bull/kotlin-retry/kotlin-retry-result/2.0.2/kotlin-retry-result-2.0.2.module";
    hash = "sha256-MLxCQbt1XO1/G4PeExkfMwO0IhTs2XYfW6XM8nrpl34=";
  };
  kotlinRetryResultPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/michael-bull/kotlin-retry/kotlin-retry-result/2.0.2/kotlin-retry-result-2.0.2.pom";
    hash = "sha256-zeVlexqJhBvIOkMyu7DDJvdxHojlk8+uYV60NRONIf8=";
  };
  kotlinRetryResultJvmModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/michael-bull/kotlin-retry/kotlin-retry-result-jvm/2.0.2/kotlin-retry-result-jvm-2.0.2.module";
    hash = "sha256-/jBMI7BEM3lr1jEUHXWC+LuTuAjGnDlIeDJOh87OrsU=";
  };
  kotlinRetryResultJvmPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/michael-bull/kotlin-retry/kotlin-retry-result-jvm/2.0.2/kotlin-retry-result-jvm-2.0.2.pom";
    hash = "sha256-D6ju8m0Kx4Pz/PRl8FbwRONicM9QZ/z6Q52zkJ2F/Ac=";
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
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    retry_cp="${finalAttrs.coroutinesCoreJvm}"
    find "${finalAttrs.src}/kotlin-retry/src/commonMain/kotlin" -name '*.kt' | sort > retry-sources.txt
    ${kotlin}/bin/kotlinc \
      -Xmulti-platform \
      -jvm-target 1.8 \
      -opt-in=kotlin.contracts.ExperimentalContracts \
      -classpath "$retry_cp" \
      -module-name kotlin-retry-jvm \
      -d "$tmp/kotlin-retry-jvm-${finalAttrs.version}.jar" \
      @retry-sources.txt

    retry_result_cp="${finalAttrs.coroutinesCoreJvm}:${kotlin_result_2_1_0}/kotlin-result-jvm-2.1.0.jar:$tmp/kotlin-retry-jvm-${finalAttrs.version}.jar"
    find "${finalAttrs.src}/kotlin-retry-result/src/commonMain/kotlin" -name '*.kt' | sort > retry-result-sources.txt
    ${kotlin}/bin/kotlinc \
      -Xmulti-platform \
      -jvm-target 1.8 \
      -opt-in=kotlin.contracts.ExperimentalContracts \
      -classpath "$retry_result_cp" \
      -module-name kotlin-retry-result-jvm \
      -d "$tmp/kotlin-retry-result-jvm-${finalAttrs.version}.jar" \
      @retry-result-sources.txt

    mkdir -p "$out"
    install -Dm644 "$tmp/kotlin-retry-jvm-${finalAttrs.version}.jar" "$out/kotlin-retry-jvm-${finalAttrs.version}.jar"
    install -Dm644 "$tmp/kotlin-retry-result-jvm-${finalAttrs.version}.jar" "$out/kotlin-retry-result-jvm-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.kotlinRetryModule}" "$out/kotlin-retry-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.kotlinRetryPom}" "$out/kotlin-retry-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.kotlinRetryJvmModule}" "$out/kotlin-retry-jvm-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.kotlinRetryJvmPom}" "$out/kotlin-retry-jvm-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.kotlinRetryResultModule}" "$out/kotlin-retry-result-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.kotlinRetryResultPom}" "$out/kotlin-retry-result-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.kotlinRetryResultJvmModule}" "$out/kotlin-retry-result-jvm-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.kotlinRetryResultJvmPom}" "$out/kotlin-retry-result-jvm-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Retry utilities for Kotlin coroutines";
    homepage = "https://github.com/michaelbull/kotlin-retry";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
