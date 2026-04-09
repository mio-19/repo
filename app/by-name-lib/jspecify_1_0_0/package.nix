{
  fetchFromGitHub,
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jspecify";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "jspecify";
    repo = "jspecify";
    tag = "v${finalAttrs.version}";
    hash = "sha256-WgVRaGm9lYhMeMM6QWUezXtUsXkaK/iPt1gj2koWNu8=";
  };

  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jspecify/jspecify/1.0.0/jspecify-1.0.0.pom";
    hash = "sha256-zauSmjuVIR9D0gkMXi0N/oRllg43i8MrNYQdqzJEM6Y=";
  };

  moduleFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jspecify/jspecify/1.0.0/jspecify-1.0.0.module";
    hash = "sha256-0wfKd6VOGKwe8artTlu+AUvS9J8p4dL4E+R8J4KDGVs=";
  };

  nativeBuildInputs = [ jdk21 ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    find "${finalAttrs.src}/src/main/java" -name '*.java' | sort > sources.txt
    mkdir -p classes
    ${jdk21}/bin/javac --release 9 -encoding UTF-8 -d classes @sources.txt

    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/jspecify-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/jspecify-${finalAttrs.version}.jar" "$out/jspecify-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.pomFile}" "$out/jspecify-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.moduleFile}" "$out/jspecify-${finalAttrs.version}.module"

    runHook postInstall
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck

    cat > JSpecifySmoke.java <<'EOF'
    import org.jspecify.annotations.NullMarked;
    import org.jspecify.annotations.Nullable;

    @NullMarked
    final class JSpecifySmoke {
      @Nullable Object value;
    }
    EOF
    ${jdk21}/bin/javac --release 9 -cp "$out/jspecify-${finalAttrs.version}.jar" JSpecifySmoke.java

    runHook postInstallCheck
  '';

  meta = with lib; {
    description = "JSpecify nullness annotations";
    homepage = "https://jspecify.dev/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
