{
  fetchFromGitHub,
  jdk21_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gson";
  version = "2.8.6";

  src = fetchFromGitHub {
    owner = "google";
    repo = "gson";
    tag = "gson-parent-${finalAttrs.version}";
    hash = "sha256-Y96Xx01C7t2vrM/WUgiu9tG5Lst2fhrgBatBFve4ZU4=";
  };

  nativeBuildInputs = [ jdk21_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir -p classes
    mkdir -p generated/com/google/gson/internal
    cat > generated/com/google/gson/internal/GsonBuildConfig.java <<EOF
    package com.google.gson.internal;

    public final class GsonBuildConfig {
      public static final String VERSION = "${finalAttrs.version}";

      private GsonBuildConfig() {
      }
    }
    EOF
    find "${finalAttrs.src}/gson/src/main/java" -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    find generated -name '*.java' | sort >> sources.txt
    javac --release 8 -encoding UTF-8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/gson-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/gson-${finalAttrs.version}.jar" "$out/gson-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/gson/pom.xml" "$out/gson-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/gson-parent-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Java serialization and deserialization library for JSON";
    homepage = "https://github.com/google/gson";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
