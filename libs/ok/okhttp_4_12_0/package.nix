{
  animal_sniffer_annotations_1_23,
  androidSdkBuilder,
  buildMavenRepository,
  fetchFromGitHub,
  fetchurl,
  jdk25_headless,
  jsr305_3_0_2,
  kotlin,
  lib,
  okio_3_16_4,
  stdenv,
}:

let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platforms-android-34
  ]);
  androidJar = "${androidSdk}/share/android-sdk/platforms/android-34/android.jar";
  # Optional SSL provider adapters are compileOnly in upstream OkHttp.
  sslRepo = buildMavenRepository {
    pathMap = baseNameOf;
    dependencies = {
      "org/conscrypt/conscrypt-openjdk-uber/2.5.2/conscrypt-openjdk-uber-2.5.2.jar" = {
        layout = "org/conscrypt/conscrypt-openjdk-uber/2.5.2/conscrypt-openjdk-uber-2.5.2.jar";
        url = "https://repo.maven.apache.org/maven2/org/conscrypt/conscrypt-openjdk-uber/2.5.2/conscrypt-openjdk-uber-2.5.2.jar";
        hash = "sha256-6vU32Y4DPQ8EUc0bjMdOAte1XsiC2mPIgGDYBrqJw0g=";
      };
      "org/openjsse/openjsse/1.1.12/openjsse-1.1.12.jar" = {
        layout = "org/openjsse/openjsse/1.1.12/openjsse-1.1.12.jar";
        url = "https://repo.maven.apache.org/maven2/org/openjsse/openjsse/1.1.12/openjsse-1.1.12.jar";
        hash = "sha256-JLPELrEXrGzpOhPWDfKPgv1DtlNhQ0Ngc5BbsdsTTzc=";
      };
      "org/bouncycastle/bcprov-jdk15to18/1.73/bcprov-jdk15to18-1.73.jar" = {
        layout = "org/bouncycastle/bcprov-jdk15to18/1.73/bcprov-jdk15to18-1.73.jar";
        url = "https://repo.maven.apache.org/maven2/org/bouncycastle/bcprov-jdk15to18/1.73/bcprov-jdk15to18-1.73.jar";
        hash = "sha256-eCM97TVxrQHrdyqYetKR1qXY05WAK2Cy3hvgXbdYxZs=";
      };
      "org/bouncycastle/bctls-jdk15to18/1.73/bctls-jdk15to18-1.73.jar" = {
        layout = "org/bouncycastle/bctls-jdk15to18/1.73/bctls-jdk15to18-1.73.jar";
        url = "https://repo.maven.apache.org/maven2/org/bouncycastle/bctls-jdk15to18/1.73/bctls-jdk15to18-1.73.jar";
        hash = "sha256-TeZcdaR5+RpLfowFicRfV4opvsK5JpsMg0x8SIojSgI=";
      };
    };
  };
  sslCp = lib.concatStringsSep ":" [
    "${sslRepo}/conscrypt-openjdk-uber-2.5.2.jar"
    "${sslRepo}/openjsse-1.1.12.jar"
    "${sslRepo}/bcprov-jdk15to18-1.73.jar"
    "${sslRepo}/bctls-jdk15to18-1.73.jar"
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "okhttp";
  version = "4.12.0";

  src = fetchFromGitHub {
    owner = "square";
    repo = "okhttp";
    tag = "parent-${finalAttrs.version}";
    hash = "sha256-o/CAqroghHiYr1fvz2+/+3qWW2sS8GeZC0i6wb3QjMk=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/squareup/okhttp3/okhttp/${finalAttrs.version}/okhttp-${finalAttrs.version}.pom";
    hash = "sha256-fHNwQKlBlSLnxQzAJ0FqcP58dinlKyGZNa3mtBGcfTg=";
  };
  module = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/squareup/okhttp3/okhttp/${finalAttrs.version}/okhttp-${finalAttrs.version}.module";
    hash = "sha256-YH4iD/ghW5Kdgpu/VPMyiU8UWbTXlZea6vy8wc6lTPM=";
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

    # OkHttp.VERSION is normally filled in from java-templates by Gradle.
    substitute "${finalAttrs.src}/okhttp/src/main/java-templates/okhttp3/OkHttp.kt" \
      "$tmp/OkHttp.kt" \
      --replace-fail '$projectVersion' '${finalAttrs.version}'

    find "${finalAttrs.src}/okhttp/src/main/kotlin" -name '*.kt' | sort > sources.txt
    echo "$tmp/OkHttp.kt" >> sources.txt

    mkdir -p "$tmp/classes"
    ${kotlin}/bin/kotlinc \
      -language-version 2.0 \
      -api-version 2.0 \
      -jvm-target 1.8 \
      -classpath "${okio_3_16_4}/okio-jvm-${okio_3_16_4.version}.jar:${animal_sniffer_annotations_1_23}/animal-sniffer-annotations-${animal_sniffer_annotations_1_23.version}.jar:${jsr305_3_0_2}/jsr305-${jsr305_3_0_2.version}.jar:${androidJar}:${sslCp}" \
      -module-name okhttp \
      -d "$tmp/classes" \
      @sources.txt

    cp -r "${finalAttrs.src}/okhttp/src/main/resources/." "$tmp/classes/"
    jar cf "$tmp/okhttp-${finalAttrs.version}.jar" -C "$tmp/classes" .

    mkdir -p "$out"
    install -Dm644 "$tmp/okhttp-${finalAttrs.version}.jar" "$out/okhttp-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.pom}" "$out/okhttp-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.module}" "$out/okhttp-${finalAttrs.version}.module"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Square’s meticulous HTTP client for Java and Kotlin";
    homepage = "https://square.github.io/okhttp/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
