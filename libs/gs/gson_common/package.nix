# for gson 2.2.4 ~ 2.10.1
{
  fetchFromGitHub,
  jdk21_headless,
  lib,
  stdenv,
}:
{
  version,
  tag ? "gson-parent-${version}",
  hash,
  buildConfig ? true,
  gsonDir ? true,
}:
let
  prefix = if gsonDir then "gson/" else "";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gson";
  inherit version;

  src = fetchFromGitHub {
    owner = "google";
    repo = "gson";
    inherit tag hash;
  };

  nativeBuildInputs = [ jdk21_headless ];

  buildPhase = ''
    runHook preBuild

    find "$src/${prefix}src/main/java" -name '*.java' ! -name 'module-info.java' > sources.txt
    ${lib.optionalString buildConfig ''
      mkdir -p generated/src/main/java/com/google/gson/internal
      substitute $src/${prefix}src/main/java-templates/com/google/gson/internal/GsonBuildConfig.java generated/src/main/java/com/google/gson/internal/GsonBuildConfig.java \
        --replace-fail '${"$"}{project.version}' "${finalAttrs.version}"
      find generated -name '*.java' >> sources.txt
    ''}
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
    ${lib.optionalString gsonDir ''
      install -Dm644 "$src/${prefix}pom.xml" "$out/gson-${finalAttrs.version}.pom"
    ''}
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
