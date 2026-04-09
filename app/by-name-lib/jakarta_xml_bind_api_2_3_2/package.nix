{
  fetchFromGitHub,
  fetchurl,
  jakarta_activation_api_1_2_1,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jakarta.xml.bind-api";
  version = "2.3.2";

  src = fetchFromGitHub {
    owner = "eclipse-ee4j";
    repo = "jaxb-api";
    tag = finalAttrs.version;
    hash = "sha256-nq2xfZoJoW8GkySOr0ahFpN7B6KnrvhvZt551uWLNjE=";
  };

  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/jakarta/xml/bind/jakarta.xml.bind-api/2.3.2/jakarta.xml.bind-api-2.3.2.pom";
    hash = "sha256-tTeziNurTMBpC50vsMdBJNZyUxc0VnrPblMTDqsTGtY=";
  };

  parentPomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/jakarta/xml/bind/jakarta.xml.bind-api-parent/2.3.2/jakarta.xml.bind-api-parent-2.3.2.pom";
    hash = "sha256-FaVbfVN8n5lwrq0o0q+XwFn2X/YQL3a70p8SR92Kbfs=";
  };

  nativeBuildInputs = [ jdk21 ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/jaxb-api/src/main/java" -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    ${jdk21}/bin/javac \
      --release 8 \
      -encoding UTF-8 \
      -cp "${jakarta_activation_api_1_2_1}/jakarta.activation-api-1.2.1.jar" \
      -d classes \
      @sources.txt

    resource_root="${finalAttrs.src}/jaxb-api/src/main/resources"
    find "$resource_root" -type f | sort | while IFS= read -r path; do
      rel_path="$(realpath --relative-to="$resource_root" "$path")"
      install -Dm644 "$path" "classes/$rel_path"
    done

    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/jakarta.xml.bind-api-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/jakarta.xml.bind-api-${finalAttrs.version}.jar" "$out/jakarta.xml.bind-api-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.pomFile}" "$out/jakarta.xml.bind-api-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.parentPomFile}" "$out/jakarta.xml.bind-api-parent-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Jakarta XML Binding API";
    homepage = "https://github.com/eclipse-ee4j/jaxb-api";
    license = [
      licenses.bsd3
      licenses.epl10
    ];
    platforms = platforms.unix;
  };
})
