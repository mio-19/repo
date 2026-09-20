{
  annotations_23_0_0,
  fetchFromGitHub,
  fetchurl,
  jdk25_headless,
  kotlin,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kotlinx-serialization";
  version = "1.7.3";

  src = fetchFromGitHub {
    owner = "Kotlin";
    repo = "kotlinx.serialization";
    tag = "v${finalAttrs.version}";
    hash = "sha256-z3h91BB4dWVlS8uIZKlsx9G0zOcLNQ9y0+x5IvclJD8=";
  };

  corePom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-serialization-core/${finalAttrs.version}/kotlinx-serialization-core-${finalAttrs.version}.pom";
    hash = "sha256-MdERd2ua93fKFnED8tYfvuqjLa5t1mNZBrdtgni6VzA=";
  };
  coreModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-serialization-core/${finalAttrs.version}/kotlinx-serialization-core-${finalAttrs.version}.module";
    hash = "sha256-OdCabgLfKzJVhECmTGKPnGBfroxPYJAyF5gzTIIXfmQ=";
  };
  coreJvmPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-serialization-core-jvm/${finalAttrs.version}/kotlinx-serialization-core-jvm-${finalAttrs.version}.pom";
    hash = "sha256-c09fdJII3QvvPZjKpZTPkiKv3w/uW2hDNHqP5k4kBCc=";
  };
  coreJvmModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-serialization-core-jvm/${finalAttrs.version}/kotlinx-serialization-core-jvm-${finalAttrs.version}.module";
    hash = "sha256-c7tMAnk/h8Ke9kvqS6AlgHb01Mlj/NpjPRJI7yS0tO8=";
  };
  jsonPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-serialization-json/${finalAttrs.version}/kotlinx-serialization-json-${finalAttrs.version}.pom";
    hash = "sha256-BaiftqSvoKHUB51YgsrTSaF/4IqYv5a30A0GplUh3H0=";
  };
  jsonModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-serialization-json/${finalAttrs.version}/kotlinx-serialization-json-${finalAttrs.version}.module";
    hash = "sha256-HPAiijWIcx1rrzvLvbCKMiUB9wQg1Q4pKrUB5V2Mz08=";
  };
  jsonJvmPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-serialization-json-jvm/${finalAttrs.version}/kotlinx-serialization-json-jvm-${finalAttrs.version}.pom";
    hash = "sha256-0zRdKAgXvgfpwnrNYHPUleF73/VxxHADTglmQgeGp90=";
  };
  jsonJvmModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-serialization-json-jvm/${finalAttrs.version}/kotlinx-serialization-json-jvm-${finalAttrs.version}.module";
    hash = "sha256-D/cOITHypldYIvdhHAXig8SuCBczA/QQSUy0Eom9PvY=";
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
    core="${finalAttrs.src}/core"
    json="${finalAttrs.src}/formats/json"
    ann="${annotations_23_0_0}/annotations-${annotations_23_0_0.version}.jar"

    find "$core/commonMain/src" -name '*.kt' | sort > "$tmp/core-common.txt"
    find "$core/jvmMain/src" -name '*.kt' | sort > "$tmp/core-jvm.txt"
    cat "$tmp/core-common.txt" "$tmp/core-jvm.txt" > "$tmp/core-sources.txt"
    core_common="$(paste -sd, "$tmp/core-common.txt")"

    ${kotlin}/bin/kotlinc \
      -Xmulti-platform \
      -Xcommon-sources="$core_common" \
      -Xexpect-actual-classes \
      -language-version 2.0 \
      -api-version 2.0 \
      -Xmetadata-version=2.0.0 \
      -jvm-target 1.8 \
      -opt-in=kotlinx.serialization.InternalSerializationApi \
      -opt-in=kotlinx.serialization.ExperimentalSerializationApi \
      -classpath "$ann" \
      -module-name kotlinx-serialization-core \
      -d "$tmp/kotlinx-serialization-core-jvm-${finalAttrs.version}.jar" \
      @"$tmp/core-sources.txt"

    find "$json/commonMain/src" -name '*.kt' | sort > "$tmp/json-common.txt"
    find "$json/jvmMain/src" -name '*.kt' | sort > "$tmp/json-jvm.txt"
    cat "$tmp/json-common.txt" "$tmp/json-jvm.txt" > "$tmp/json-sources.txt"
    json_common="$(paste -sd, "$tmp/json-common.txt")"

    ${kotlin}/bin/kotlinc \
      -Xmulti-platform \
      -Xcommon-sources="$json_common" \
      -Xexpect-actual-classes \
      -language-version 2.0 \
      -api-version 2.0 \
      -Xmetadata-version=2.0.0 \
      -jvm-target 1.8 \
      -opt-in=kotlinx.serialization.InternalSerializationApi \
      -opt-in=kotlinx.serialization.ExperimentalSerializationApi \
      -opt-in=kotlinx.serialization.json.internal.JsonFriendModuleApi \
      -opt-in=kotlinx.serialization.internal.CoreFriendModuleApi \
      -classpath "$tmp/kotlinx-serialization-core-jvm-${finalAttrs.version}.jar:$ann" \
      -module-name kotlinx-serialization-json \
      -d "$tmp/kotlinx-serialization-json-jvm-${finalAttrs.version}.jar" \
      @"$tmp/json-sources.txt"

    # Serialization compiler plugin reads Implementation-Version from the core jar
    # manifest; without it it reports "core version is too low".
    cat > "$tmp/core-manifest.mf" <<EOF
    Manifest-Version: 1.0
    Implementation-Version: ${finalAttrs.version}
    Require-Kotlin-Version: 2.0.0-RC1
    Multi-Release: true

    EOF
    jar ufm "$tmp/kotlinx-serialization-core-jvm-${finalAttrs.version}.jar" "$tmp/core-manifest.mf"

    mkdir -p "$out"
    install -Dm644 "$tmp/kotlinx-serialization-core-jvm-${finalAttrs.version}.jar" \
      "$out/kotlinx-serialization-core-jvm-${finalAttrs.version}.jar"
    install -Dm644 "$tmp/kotlinx-serialization-json-jvm-${finalAttrs.version}.jar" \
      "$out/kotlinx-serialization-json-jvm-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.corePom}" "$out/kotlinx-serialization-core-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.coreModule}" "$out/kotlinx-serialization-core-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.coreJvmPom}" "$out/kotlinx-serialization-core-jvm-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.coreJvmModule}" "$out/kotlinx-serialization-core-jvm-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.jsonPom}" "$out/kotlinx-serialization-json-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.jsonModule}" "$out/kotlinx-serialization-json-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.jsonJvmPom}" "$out/kotlinx-serialization-json-jvm-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.jsonJvmModule}" "$out/kotlinx-serialization-json-jvm-${finalAttrs.version}.module"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Kotlin multiplatform serialization runtime library";
    homepage = "https://github.com/Kotlin/kotlinx.serialization";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
