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

  buildPhase = ''
    runHook preBuild

    mkdir -p generated/src/main/java/com/google/gson/internal
    substitute $src/gson/src/main/java-templates/com/google/gson/internal/GsonBuildConfig.java generated/src/main/java/com/google/gson/internal/GsonBuildConfig.java \
      --replace-fail '${"$"}{project.version}' "${finalAttrs.version}"
    find "$src/gson/src/main/java" -name '*.java' ! -name 'module-info.java' > sources.txt
    find generated -name '*.java' >> sources.txt
    mkdir classes
    javac --release 8 -encoding UTF-8 -d classes @sources.txt

    cd classes
    jar cf "../gson-${finalAttrs.version}.jar" .
    cd ..

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    install -Dm644 "./gson-${finalAttrs.version}.jar" "$out/gson-${finalAttrs.version}.jar"
    install -Dm644 "$src/gson/pom.xml" "$out/gson-${finalAttrs.version}.pom"
    install -Dm644 "$src/pom.xml" "$out/gson-parent-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Java serialization and deserialization library for JSON";
    homepage = "https://github.com/google/gson";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
