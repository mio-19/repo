{
  fetchFromGitHub,
  fetchurl,
  jdk25,
  kotlin,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kotlinx-io";
  version = "0.8.2";

  src = fetchFromGitHub {
    owner = "Kotlin";
    repo = "kotlinx-io";
    tag = finalAttrs.version;
    hash = "sha256-j44eljRpL4qwDbHF0r7vgvlR/IQUTAXG2Fjy07yjEYw=";
  };

  bytestringModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-io-bytestring/0.8.2/kotlinx-io-bytestring-0.8.2.module";
    hash = "sha256-Rr6OR2rNrlReNYRmWuWDzEqYr8YU6Ms9DGTI1Puvk7o=";
  };
  bytestringPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-io-bytestring/0.8.2/kotlinx-io-bytestring-0.8.2.pom";
    hash = "sha256-VNISwY3EmqVjNq7MgqP2u09ibxRiS0xZ3WQQifP15e0=";
  };
  bytestringJvmModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-io-bytestring-jvm/0.8.2/kotlinx-io-bytestring-jvm-0.8.2.module";
    hash = "sha256-zLwAxm9EwR025LLI3him8gFK409V2vIarbRpXuB5qjs=";
  };
  bytestringJvmPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-io-bytestring-jvm/0.8.2/kotlinx-io-bytestring-jvm-0.8.2.pom";
    hash = "sha256-FRY1+uo9dZloCkuDrXiLcAAmFtXFdnSdh+RNgxM3iQU=";
  };
  coreModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-io-core/0.8.2/kotlinx-io-core-0.8.2.module";
    hash = "sha256-5HEw0i3rmVYcjoMa96o4FP0ZjjMKCm0RbFIVN2j9ocE=";
  };
  corePom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-io-core/0.8.2/kotlinx-io-core-0.8.2.pom";
    hash = "sha256-yXvIo+dC1U/J2Vp2EfeXDYVTrM4zvhdfGnyCEK5sGiQ=";
  };
  coreJvmModule = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-io-core-jvm/0.8.2/kotlinx-io-core-jvm-0.8.2.module";
    hash = "sha256-CwPCv3wseY6naj73f/gPOYVNOFhBsefR/jbFxQpRXd0=";
  };
  coreJvmPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-io-core-jvm/0.8.2/kotlinx-io-core-jvm-0.8.2.pom";
    hash = "sha256-4gGfv0x3cnzBGQLazKfnHBBtW/ALFBrnUqYZjakVscg=";
  };

  nativeBuildInputs = [
    jdk25
    kotlin
  ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    export JAVA_HOME=${jdk25}
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    find "${finalAttrs.src}/bytestring/common/src" -name '*.kt' | sort > bytestring-common-sources.txt
    find "${finalAttrs.src}/bytestring/jvm/src" -name '*.kt' | sort > bytestring-jvm-sources.txt
    cat bytestring-common-sources.txt bytestring-jvm-sources.txt > bytestring-sources.txt
    bytestring_common_sources="$(paste -sd, bytestring-common-sources.txt)"
    ${kotlin}/bin/kotlinc \
      -Xmulti-platform \
      -Xcommon-sources="$bytestring_common_sources" \
      -jvm-target 1.8 \
      -module-name kotlinx-io-bytestring-jvm \
      -d "$tmp/kotlinx-io-bytestring-jvm-${finalAttrs.version}.jar" \
      @bytestring-sources.txt

    find "${finalAttrs.src}/core/common/src" -name '*.kt' | sort > core-common-sources.txt
    find "${finalAttrs.src}/core/jvm/src" -name '*.kt' | sort > core-jvm-sources.txt
    cat core-common-sources.txt core-jvm-sources.txt > core-sources.txt
    core_common_sources="$(paste -sd, core-common-sources.txt)"
    ${kotlin}/bin/kotlinc \
      -Xmulti-platform \
      -Xcommon-sources="$core_common_sources" \
      -jvm-target 1.8 \
      -classpath "$tmp/kotlinx-io-bytestring-jvm-${finalAttrs.version}.jar" \
      -module-name kotlinx-io-core-jvm \
      -d "$tmp/kotlinx-io-core-jvm-${finalAttrs.version}.jar" \
      @core-sources.txt

    mkdir -p "$out"
    install -Dm644 "$tmp/kotlinx-io-bytestring-jvm-${finalAttrs.version}.jar" "$out/kotlinx-io-bytestring-jvm-${finalAttrs.version}.jar"
    install -Dm644 "$tmp/kotlinx-io-core-jvm-${finalAttrs.version}.jar" "$out/kotlinx-io-core-jvm-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.bytestringModule}" "$out/kotlinx-io-bytestring-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.bytestringPom}" "$out/kotlinx-io-bytestring-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.bytestringJvmModule}" "$out/kotlinx-io-bytestring-jvm-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.bytestringJvmPom}" "$out/kotlinx-io-bytestring-jvm-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.coreModule}" "$out/kotlinx-io-core-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.corePom}" "$out/kotlinx-io-core-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.coreJvmModule}" "$out/kotlinx-io-core-jvm-${finalAttrs.version}.module"
    install -Dm644 "${finalAttrs.coreJvmPom}" "$out/kotlinx-io-core-jvm-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Multiplatform IO library for Kotlin";
    homepage = "https://github.com/Kotlin/kotlinx-io";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
