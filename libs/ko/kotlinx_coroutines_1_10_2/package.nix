{
  animal_sniffer_annotations_1_23,
  androidSdkBuilder,
  annotations_23_0_0,
  buildMavenRepository,
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
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platforms-android-34
  ]);
  androidJar = "${androidSdk}/share/android-sdk/platforms/android-34/android.jar";
  # Build-time jars: atomicfu for compile, plus transformer toolchain (not shipped in outputs).
  toolRepo = buildMavenRepository {
    pathMap = baseNameOf;
    dependencies = {
      "org/jetbrains/kotlinx/atomicfu-jvm/0.26.1/atomicfu-jvm-0.26.1.jar" = {
        layout = "org/jetbrains/kotlinx/atomicfu-jvm/0.26.1/atomicfu-jvm-0.26.1.jar";
        url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/atomicfu-jvm/0.26.1/atomicfu-jvm-0.26.1.jar";
        hash = "sha256-k3wib9L2KtQ4TtJxDq43dQ3pUD9yYSuMz6222P9j+/I=";
      };
      "org/jetbrains/kotlinx/atomicfu-transformer/0.26.1/atomicfu-transformer-0.26.1.jar" = {
        layout = "org/jetbrains/kotlinx/atomicfu-transformer/0.26.1/atomicfu-transformer-0.26.1.jar";
        url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/atomicfu-transformer/0.26.1/atomicfu-transformer-0.26.1.jar";
        hash = "sha256-8Wgu0xb3jZRdtuZTXSpNenLpiMJtAJEuxK6yh9Puq0E=";
      };
      "org/ow2/asm/asm/9.7/asm-9.7.jar" = {
        layout = "org/ow2/asm/asm/9.7/asm-9.7.jar";
        url = "https://repo.maven.apache.org/maven2/org/ow2/asm/asm/9.7/asm-9.7.jar";
        hash = "sha256-rfRtXjSUC98Ujs3Sap7o7qlElqcgNP9xQQZrPupcTp0=";
      };
      "org/ow2/asm/asm-commons/9.7/asm-commons-9.7.jar" = {
        layout = "org/ow2/asm/asm-commons/9.7/asm-commons-9.7.jar";
        url = "https://repo.maven.apache.org/maven2/org/ow2/asm/asm-commons/9.7/asm-commons-9.7.jar";
        hash = "sha256-OJvCR5WOBJ/JoECNOYySxtNwwYA1EgOV1Muh2dkwS3o=";
      };
      "org/ow2/asm/asm-tree/9.7/asm-tree-9.7.jar" = {
        layout = "org/ow2/asm/asm-tree/9.7/asm-tree-9.7.jar";
        url = "https://repo.maven.apache.org/maven2/org/ow2/asm/asm-tree/9.7/asm-tree-9.7.jar";
        hash = "sha256-YvSzvENgRcGstcO6LY7FVuwzaQk9f10Gx0frBLVtUrE=";
      };
      "org/ow2/asm/asm-util/9.7/asm-util-9.7.jar" = {
        layout = "org/ow2/asm/asm-util/9.7/asm-util-9.7.jar";
        url = "https://repo.maven.apache.org/maven2/org/ow2/asm/asm-util/9.7/asm-util-9.7.jar";
        hash = "sha256-N6ZBTTZkGXPxrxBJN8ldbZIbLdtNYSxmxanysT/BQhE=";
      };
      "org/slf4j/slf4j-api/1.8.0-alpha2/slf4j-api-1.8.0-alpha2.jar" = {
        layout = "org/slf4j/slf4j-api/1.8.0-alpha2/slf4j-api-1.8.0-alpha2.jar";
        url = "https://repo.maven.apache.org/maven2/org/slf4j/slf4j-api/1.8.0-alpha2/slf4j-api-1.8.0-alpha2.jar";
        hash = "sha256-CcMB+ICGrfcF/ROqvSDMshSNjqZN+jx+SCtckJBGx5I=";
      };
      "org/slf4j/slf4j-simple/1.8.0-alpha2/slf4j-simple-1.8.0-alpha2.jar" = {
        layout = "org/slf4j/slf4j-simple/1.8.0-alpha2/slf4j-simple-1.8.0-alpha2.jar";
        url = "https://repo.maven.apache.org/maven2/org/slf4j/slf4j-simple/1.8.0-alpha2/slf4j-simple-1.8.0-alpha2.jar";
        hash = "sha256-ObJOKXTUdzen28wQKUiyzOcb0wNUEKnRb5gRhQhgtcI=";
      };
      "org/mozilla/rhino/1.7.10/rhino-1.7.10.jar" = {
        layout = "org/mozilla/rhino/1.7.10/rhino-1.7.10.jar";
        url = "https://repo.maven.apache.org/maven2/org/mozilla/rhino/1.7.10/rhino-1.7.10.jar";
        hash = "sha256-OOswAM9WuMdVnuVYhmp2juvL8lQXRSLWQEt/B491wtQ=";
      };
    };
  };
  atomicfuJvm = "${toolRepo}/atomicfu-jvm-0.26.1.jar";
  coreClasspath = "${annotations_23_0_0}/annotations-${annotations_23_0_0.version}.jar:${atomicfuJvm}:${animal_sniffer_annotations_1_23}/animal-sniffer-annotations-${animal_sniffer_annotations_1_23.version}.jar:${androidJar}";
  atomicfuTransformerCp = lib.concatStringsSep ":" [
    "${toolRepo}/atomicfu-transformer-0.26.1.jar"
    "${toolRepo}/asm-9.7.jar"
    "${toolRepo}/asm-commons-9.7.jar"
    "${toolRepo}/asm-tree-9.7.jar"
    "${toolRepo}/asm-util-9.7.jar"
    "${toolRepo}/slf4j-api-1.8.0-alpha2.jar"
    "${toolRepo}/slf4j-simple-1.8.0-alpha2.jar"
    "${toolRepo}/rhino-1.7.10.jar"
    "${kotlin}/lib/kotlin-stdlib.jar"
    "${kotlin}/lib/kotlin-metadata-jvm.jar"
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "kotlinx-coroutines";
  version = "1.10.2";

  src = fetchFromGitHub {
    owner = "Kotlin";
    repo = "kotlinx.coroutines";
    tag = finalAttrs.version;
    hash = "sha256-FQcNPrk2Q5EDaQViyUEnPuBHUMeqQcdHZnXWf51WkXc=";
  };

  corePom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-coroutines-core/${finalAttrs.version}/kotlinx-coroutines-core-${finalAttrs.version}.pom";
    hash = "sha256-UZ2lQACW80YqTa6AeDrQUEE9S8gex65T+udq7wzL7Uw=";
  };
  coreModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-coroutines-core/${finalAttrs.version}/kotlinx-coroutines-core-${finalAttrs.version}.module";
    hash = "sha256-j+JUF35xGnzRijwG2CQvzpRfQcLMoT3BmzOuQqVDUBY=";
  };
  coreJvmPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-coroutines-core-jvm/${finalAttrs.version}/kotlinx-coroutines-core-jvm-${finalAttrs.version}.pom";
    hash = "sha256-ZY9Xa5bIMuc4JAatsZfWTY4ul94Q6W36NwDez6KmDe8=";
  };
  coreJvmModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-coroutines-core-jvm/${finalAttrs.version}/kotlinx-coroutines-core-jvm-${finalAttrs.version}.module";
    hash = "sha256-6eSnS02/4PXr7tiNSfNUbD7DCJQZsg5SUEAxNcLGTFM=";
  };
  androidPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-coroutines-android/${finalAttrs.version}/kotlinx-coroutines-android-${finalAttrs.version}.pom";
    hash = "sha256-uS02cuf56PTE4qsYfD4x/sxQZJY5b0pfJ+4clXpCsxk=";
  };
  androidModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-coroutines-android/${finalAttrs.version}/kotlinx-coroutines-android-${finalAttrs.version}.module";
    hash = "sha256-CS/jgQPuxi6UVAygzWEDnvj32ORmlOwDO+H2Pw6iAT0=";
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
    core="${finalAttrs.src}/kotlinx-coroutines-core"

    # Compile-only stub for androidx.annotation.VisibleForTesting (android module).
    mkdir -p "$tmp/annotation-classes"
    ${kotlin}/bin/kotlinc \
      -jvm-target 1.8 \
      -d "$tmp/annotation-classes" \
      ${./VisibleForTesting.kt}
    jar cf "$tmp/androidx-annotation-stub.jar" -C "$tmp/annotation-classes" .

    # jdk8 sources were merged into jvm/ in 1.10.x
    find "$core/common/src" -name '*.kt' | sort > "$tmp/common.txt"
    find "$core/concurrent/src" -name '*.kt' | sort > "$tmp/concurrent.txt"
    find "$core/jvm/src" -name '*.kt' | sort > "$tmp/jvm.txt"

    {
      echo '-Xmulti-platform'
      echo '-Xfragments=common,concurrent,jvm'
      echo '-Xfragment-refines=concurrent:common,jvm:concurrent'
      echo '-Xexpect-actual-classes'
      echo '-language-version'
      echo '2.0'
      echo '-api-version'
      echo '2.0'
      echo '-Xmetadata-version=2.0.0'
      echo '-jvm-target'
      echo '1.8'
      echo "-classpath"
      echo "${coreClasspath}"
      echo '-opt-in=kotlin.RequiresOptIn'
      echo '-opt-in=kotlin.ExperimentalMultiplatform'
      echo '-opt-in=kotlin.experimental.ExperimentalTypeInference'
      echo '-opt-in=kotlinx.coroutines.ExperimentalCoroutinesApi'
      echo '-opt-in=kotlinx.coroutines.InternalCoroutinesApi'
      echo '-module-name'
      echo 'kotlinx-coroutines-core'
      echo '-d'
      echo "$tmp/core-classes"
      while IFS= read -r f; do echo "-Xfragment-sources=common:$f"; echo "$f"; done < "$tmp/common.txt"
      while IFS= read -r f; do echo "-Xfragment-sources=concurrent:$f"; echo "$f"; done < "$tmp/concurrent.txt"
      while IFS= read -r f; do echo "-Xfragment-sources=jvm:$f"; echo "$f"; done < "$tmp/jvm.txt"
    } > "$tmp/kotlinc.args"

    mkdir -p "$tmp/core-classes"
    ${kotlin}/bin/kotlinc @"$tmp/kotlinc.args"

    # Replace atomicfu APIs with java.util.concurrent.atomic (as Maven Central does).
    # Run before copying store resources so the transformer does not rewrite read-only files.
    java -cp "${atomicfuTransformerCp}" \
      kotlinx.atomicfu.transformer.AtomicFUTransformerKt \
      "$tmp/core-classes"

    cp -r "$core/jvm/resources/." "$tmp/core-classes/"
    jar cf "$tmp/kotlinx-coroutines-core-jvm-${finalAttrs.version}.jar" -C "$tmp/core-classes" .

    find "${finalAttrs.src}/ui/kotlinx-coroutines-android/src" -name '*.kt' | sort > "$tmp/android.txt"
    mkdir -p "$tmp/android-classes"
    ${kotlin}/bin/kotlinc \
      -language-version 2.0 \
      -api-version 2.0 \
      -Xmetadata-version=2.0.0 \
      -jvm-target 1.8 \
      -classpath "$tmp/kotlinx-coroutines-core-jvm-${finalAttrs.version}.jar:${coreClasspath}:$tmp/androidx-annotation-stub.jar" \
      -opt-in=kotlin.RequiresOptIn \
      -opt-in=kotlin.ExperimentalMultiplatform \
      -opt-in=kotlin.experimental.ExperimentalTypeInference \
      -opt-in=kotlinx.coroutines.ExperimentalCoroutinesApi \
      -opt-in=kotlinx.coroutines.InternalCoroutinesApi \
      -module-name kotlinx-coroutines-android \
      -d "$tmp/android-classes" \
      @"$tmp/android.txt"

    # ServiceLoader metadata for MainDispatcherFactory
    if [ -d "${finalAttrs.src}/ui/kotlinx-coroutines-android/resources" ]; then
      cp -r "${finalAttrs.src}/ui/kotlinx-coroutines-android/resources/." "$tmp/android-classes/"
    fi
    jar cf "$tmp/kotlinx-coroutines-android-${finalAttrs.version}.jar" -C "$tmp/android-classes" .

    mkdir -p "$out"
    install -Dm644 "$tmp/kotlinx-coroutines-core-jvm-${finalAttrs.version}.jar" \
      "$out/kotlinx-coroutines-core-jvm-${finalAttrs.version}.jar"
    install -Dm644 "$tmp/kotlinx-coroutines-android-${finalAttrs.version}.jar" \
      "$out/kotlinx-coroutines-android-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.corePom}" "$out/kotlinx-coroutines-core-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.coreModule}" "$out/kotlinx-coroutines-core-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.coreJvmPom}" "$out/kotlinx-coroutines-core-jvm-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.coreJvmModule}" "$out/kotlinx-coroutines-core-jvm-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.androidPom}" "$out/kotlinx-coroutines-android-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.androidModule}" "$out/kotlinx-coroutines-android-${finalAttrs.version}.module"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = checkMavenProvides finalAttrs;

  meta = with lib; {
    description = "Library support for Kotlin coroutines";
    homepage = "https://github.com/Kotlin/kotlinx.coroutines";
    license = licenses.asl20;
    platforms = platforms.unix;
    sourceProvenance = with sourceTypes; [ fromSource ];
    mavenProvides = exposeMavenProvides finalAttrs;
    mavenProvidesInternal = {
      "org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:${finalAttrs.version}" = {
        "kotlinx-coroutines-core-jvm-${finalAttrs.version}.jar" =
          "$out/kotlinx-coroutines-core-jvm-${finalAttrs.version}.jar";
        "kotlinx-coroutines-core-jvm-${finalAttrs.version}.module" =
          "$out/kotlinx-coroutines-core-jvm-${finalAttrs.version}.module";
        "kotlinx-coroutines-core-jvm-${finalAttrs.version}.pom" =
          "$out/kotlinx-coroutines-core-jvm-${finalAttrs.version}.pom";
      };
      "org.jetbrains.kotlinx:kotlinx-coroutines-core:${finalAttrs.version}" = {
        "kotlinx-coroutines-core-${finalAttrs.version}.module" =
          "$out/kotlinx-coroutines-core-${finalAttrs.version}.module";
        "kotlinx-coroutines-core-${finalAttrs.version}.pom" =
          "$out/kotlinx-coroutines-core-${finalAttrs.version}.pom";
      };
      "org.jetbrains.kotlinx:kotlinx-coroutines-android:${finalAttrs.version}" = {
        "kotlinx-coroutines-android-${finalAttrs.version}.jar" =
          "$out/kotlinx-coroutines-android-${finalAttrs.version}.jar";
        "kotlinx-coroutines-android-${finalAttrs.version}.module" =
          "$out/kotlinx-coroutines-android-${finalAttrs.version}.module";
        "kotlinx-coroutines-android-${finalAttrs.version}.pom" =
          "$out/kotlinx-coroutines-android-${finalAttrs.version}.pom";
      };
    };
  };
})
