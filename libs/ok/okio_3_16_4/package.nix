{
  fetchFromGitHub,
  fetchurl,
  jdk25_headless,
  kotlin,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "okio";
  version = "3.16.4";

  src = fetchFromGitHub {
    owner = "square";
    repo = "okio";
    tag = "parent-${finalAttrs.version}";
    hash = "sha256-4plfZ0gdPxYdyy3ShT1OP57rV743CC1Y7fzP/JXjMr8=";
  };

  okioPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/squareup/okio/okio/${finalAttrs.version}/okio-${finalAttrs.version}.pom";
    hash = "sha256-CPvpfh4ugVoUyvFv9ayHCFEb713ec51gwHE5UYdtomM=";
  };
  okioModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/squareup/okio/okio/${finalAttrs.version}/okio-${finalAttrs.version}.module";
    hash = "sha256-yEQahybbGk+dTzngaOu0LfalnWR+MqnGHBW1OQ7VklI=";
  };
  okioJvmPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/squareup/okio/okio-jvm/${finalAttrs.version}/okio-jvm-${finalAttrs.version}.pom";
    hash = "sha256-ZnePTQWXvOY/kewADFdcwCmzIB990JLLgIh1FVs+hqE=";
  };
  okioJvmModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/squareup/okio/okio-jvm/${finalAttrs.version}/okio-jvm-${finalAttrs.version}.module";
    hash = "sha256-kAjVopVKBoxoSCdPbuvf9IsUpw28aT0zAuCMVwzKAy8=";
  };

  nativeBuildInputs = [
    jdk25_headless
    kotlin
  ];

  dontConfigure = true;
  dontUnpack = true;

  # jvmMain dependsOn zlibMain + systemFileSystemMain + nonJsMain (all refine commonMain).
  installPhase = ''
    runHook preInstall

    export JAVA_HOME=${jdk25_headless.passthru.home}
    tmp="$(mktemp -d)"
    okioSrc="${finalAttrs.src}/okio/src"

    find "$okioSrc/commonMain/kotlin" -name '*.kt' | sort > "$tmp/common.txt"
    find "$okioSrc/zlibMain/kotlin" -name '*.kt' | sort > "$tmp/zlib.txt"
    find "$okioSrc/systemFileSystemMain/kotlin" -name '*.kt' | sort > "$tmp/systemFileSystem.txt"
    find "$okioSrc/nonJsMain/kotlin" -name '*.kt' | sort > "$tmp/nonJs.txt"
    find "$okioSrc/jvmMain/kotlin" -name '*.kt' | sort > "$tmp/jvm.txt"

    {
      echo '-Xmulti-platform'
      echo '-Xfragments=common,zlib,systemFileSystem,nonJs,jvm'
      echo '-Xfragment-refines=zlib:common,systemFileSystem:common,nonJs:common,jvm:zlib,jvm:systemFileSystem,jvm:nonJs'
      echo '-Xexpect-actual-classes'
      # Match Maven Central metadata so Kotlin <2.4 app compilers can read the jar.
      echo '-language-version'
      echo '2.0'
      echo '-api-version'
      echo '2.0'
      echo '-Xmetadata-version=2.0.0'
      echo '-jvm-target'
      echo '1.8'
      echo '-opt-in=kotlin.contracts.ExperimentalContracts'
      echo '-module-name'
      echo 'okio'
      echo '-d'
      echo "$tmp/okio-jvm-${finalAttrs.version}.jar"
      while IFS= read -r f; do echo "-Xfragment-sources=common:$f"; echo "$f"; done < "$tmp/common.txt"
      while IFS= read -r f; do echo "-Xfragment-sources=zlib:$f"; echo "$f"; done < "$tmp/zlib.txt"
      while IFS= read -r f; do echo "-Xfragment-sources=systemFileSystem:$f"; echo "$f"; done < "$tmp/systemFileSystem.txt"
      while IFS= read -r f; do echo "-Xfragment-sources=nonJs:$f"; echo "$f"; done < "$tmp/nonJs.txt"
      while IFS= read -r f; do echo "-Xfragment-sources=jvm:$f"; echo "$f"; done < "$tmp/jvm.txt"
    } > "$tmp/kotlinc.args"

    ${kotlin}/bin/kotlinc @"$tmp/kotlinc.args"

    mkdir -p "$out"
    install -Dm644 "$tmp/okio-jvm-${finalAttrs.version}.jar" "$out/okio-jvm-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.okioPom}" "$out/okio-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.okioModule}" "$out/okio-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.okioJvmPom}" "$out/okio-jvm-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.okioJvmModule}" "$out/okio-jvm-${finalAttrs.version}.module"

    runHook postInstall
  '';

  meta = with lib; {
    description = "A modern I/O library for Android, Java, and Kotlin Multiplatform";
    homepage = "https://square.github.io/okio/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
