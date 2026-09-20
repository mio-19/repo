{
  animal_sniffer_annotations_1_23,
  buildMavenRepository,
  fetchFromGitHub,
  fetchurl,
  jdk25_headless,
  kotlin,
  lib,
  okio_3_16_4,
  stdenv,
}:

let
  # Optional SSL provider adapters are compileOnly in upstream OkHttp.
  sslRepo = buildMavenRepository {
    pathMap = baseNameOf;
    dependencies = {
      "org/conscrypt/conscrypt-openjdk-uber/2.5.2/conscrypt-openjdk-uber-2.5.2.jar" = {
        layout = "org/conscrypt/conscrypt-openjdk-uber/2.5.2/conscrypt-openjdk-uber-2.5.2.jar";
        url = "https://repo.maven.apache.org/maven2/org/conscrypt/conscrypt-openjdk-uber/2.5.2/conscrypt-openjdk-uber-2.5.2.jar";
        hash = "sha256-6vU32Y4DPQ8EUc0bjMdOAte1XsiC2mPIgGDYBrqJw0g=";
      };
      "org/openjsse/openjsse/1.1.14/openjsse-1.1.14.jar" = {
        layout = "org/openjsse/openjsse/1.1.14/openjsse-1.1.14.jar";
        url = "https://repo.maven.apache.org/maven2/org/openjsse/openjsse/1.1.14/openjsse-1.1.14.jar";
        hash = "sha256-EQdi7X9OuDS/KKjTCxGNilf3WfLIM+UwlfU5z75waC4=";
      };
      "org/bouncycastle/bcprov-jdk15to18/1.82/bcprov-jdk15to18-1.82.jar" = {
        layout = "org/bouncycastle/bcprov-jdk15to18/1.82/bcprov-jdk15to18-1.82.jar";
        url = "https://repo.maven.apache.org/maven2/org/bouncycastle/bcprov-jdk15to18/1.82/bcprov-jdk15to18-1.82.jar";
        hash = "sha256-nJzOywigsAvSp0r6ZWfYHWGgK7oTZPJOM/oMTB6SmCE=";
      };
      "org/bouncycastle/bctls-jdk15to18/1.82/bctls-jdk15to18-1.82.jar" = {
        layout = "org/bouncycastle/bctls-jdk15to18/1.82/bctls-jdk15to18-1.82.jar";
        url = "https://repo.maven.apache.org/maven2/org/bouncycastle/bctls-jdk15to18/1.82/bctls-jdk15to18-1.82.jar";
        hash = "sha256-Aomt6BwSp05HJuDylhkzAEVG/9dAw6POgh+7vSBx4/c=";
      };
    };
  };
  sslCp = lib.concatStringsSep ":" [
    "${sslRepo}/conscrypt-openjdk-uber-2.5.2.jar"
    "${sslRepo}/openjsse-1.1.14.jar"
    "${sslRepo}/bcprov-jdk15to18-1.82.jar"
    "${sslRepo}/bctls-jdk15to18-1.82.jar"
  ];
  okioJar = "${okio_3_16_4}/okio-jvm-${okio_3_16_4.version}.jar";
  animalJar = "${animal_sniffer_annotations_1_23}/animal-sniffer-annotations-${animal_sniffer_annotations_1_23.version}.jar";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "okhttp";
  version = "5.3.2";

  src = fetchFromGitHub {
    owner = "square";
    repo = "okhttp";
    tag = "parent-${finalAttrs.version}";
    hash = "sha256-oCIFL7EyO/Wo7gSWFQoNIw2gktSRna8ah6hhCjT7OHk=";
  };

  okhttpPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/squareup/okhttp3/okhttp/${finalAttrs.version}/okhttp-${finalAttrs.version}.pom";
    hash = "sha256-+Uc3LE3YSPdSrvaDfRUXRhxETB1Dr1rrFebyvXN7sHI=";
  };
  okhttpModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/squareup/okhttp3/okhttp/${finalAttrs.version}/okhttp-${finalAttrs.version}.module";
    hash = "sha256-C3d0IDpza10i/EW1IuySe74skEh91YZbZOV+AGBeRxE=";
  };
  okhttpJvmPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/squareup/okhttp3/okhttp-jvm/${finalAttrs.version}/okhttp-jvm-${finalAttrs.version}.pom";
    hash = "sha256-ruhxl7v7LXQktiQdMA6wy/+xhEycqwEpyuU5BAizP6Q=";
  };
  okhttpJvmModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/squareup/okhttp3/okhttp-jvm/${finalAttrs.version}/okhttp-jvm-${finalAttrs.version}.module";
    hash = "sha256-ORMM9gZSgNkN4ugnNQwxcLtV6y9INcK0QW87g7Hxq4U=";
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
    srcRoot="${finalAttrs.src}/okhttp/src"
    idnSrc="${finalAttrs.src}/okhttp-idna-mapping-table"

    # Generate IdnaMappingTableInstance.kt (normally a Gradle task using KotlinPoet).
    mkdir -p "$tmp/idn-resources"
    cp -r "$idnSrc/src/main/resources/." "$tmp/idn-resources/"
    jar cf "$tmp/idn-resources.jar" -C "$tmp/idn-resources" .

    find "$idnSrc/src/main/kotlin" -name '*.kt' ! -name 'GenerateIdnaMappingTableCode.kt' | sort > "$tmp/idn-sources.txt"
    echo "${./generate-idna.kt}" >> "$tmp/idn-sources.txt"

    ${kotlin}/bin/kotlinc \
      -jvm-target 1.8 \
      -classpath "${okioJar}:$tmp/idn-resources.jar" \
      -d "$tmp/idn-gen.jar" \
      @"$tmp/idn-sources.txt"

    mkdir -p "$tmp/gen"
    ${kotlin}/bin/kotlin \
      -cp "$tmp/idn-gen.jar:${okioJar}:$tmp/idn-resources.jar" \
      okhttp3.internal.idn.GenerateIdnaMain \
      "$tmp/gen"

    find "$srcRoot/commonJvmAndroid/kotlin" -name '*.kt' | sort > common.txt
    # GraalVM native-image helpers need the Graal SDK; skip for the JVM jar.
    find "$srcRoot/jvmMain/kotlin" -name '*.kt' ! -path '*/graal/*' | sort > jvm.txt

    # CONST_VERSION is normally filled in from kotlinTemplates by Gradle.
    mkdir -p "$tmp/gen/okhttp3/internal"
    substitute "$srcRoot/commonJvmAndroid/kotlinTemplates/okhttp3/internal/-InternalVersion.kt" \
      "$tmp/gen/okhttp3/internal/-InternalVersion.kt" \
      --replace-fail '$projectVersion' '${finalAttrs.version}'

    echo "$tmp/gen/okhttp3/internal/-InternalVersion.kt" >> common.txt
    echo "$tmp/gen/okhttp3/internal/idn/IdnaMappingTableInstance.kt" >> common.txt

    cat common.txt jvm.txt > sources.txt
    common_sources="$(paste -sd, common.txt)"

    mkdir -p "$tmp/classes"
    ${kotlin}/bin/kotlinc \
      -Xmulti-platform \
      -Xcommon-sources="$common_sources" \
      -Xexpect-actual-classes \
      -language-version 2.0 \
      -api-version 2.0 \
      -Xmetadata-version=2.0.0 \
      -jvm-target 1.8 \
      -classpath "${okioJar}:${animalJar}:${sslCp}" \
      -module-name okhttp \
      -d "$tmp/classes" \
      @sources.txt

    cp -r "$srcRoot/jvmMain/resources/." "$tmp/classes/"
    jar cf "$tmp/okhttp-jvm-${finalAttrs.version}.jar" -C "$tmp/classes" .

    mkdir -p "$out"
    install -Dm644 "$tmp/okhttp-jvm-${finalAttrs.version}.jar" "$out/okhttp-jvm-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.okhttpPom}" "$out/okhttp-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.okhttpModule}" "$out/okhttp-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.okhttpJvmPom}" "$out/okhttp-jvm-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.okhttpJvmModule}" "$out/okhttp-jvm-${finalAttrs.version}.module"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Square’s meticulous HTTP client for Java and Kotlin";
    homepage = "https://square.github.io/okhttp/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
