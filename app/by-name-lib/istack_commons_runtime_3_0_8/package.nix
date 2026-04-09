{
  fetchFromGitHub,
  fetchurl,
  jakarta_activation_api_1_2_1,
  jdk25,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "istack-commons-runtime";
  version = "3.0.8";

  src = fetchFromGitHub {
    owner = "eclipse-ee4j";
    repo = "jaxb-istack-commons";
    tag = finalAttrs.version;
    hash = "sha256-Q/MDU1+kjAKJy4MMMEqaTgg+vGqhd2MUFpFBNXY1lGg=";
  };

  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/sun/istack/istack-commons-runtime/3.0.8/istack-commons-runtime-3.0.8.pom";
    hash = "sha256-wuAU00y4TtKH0GSYbEXDBaQSQiinM37M9sQh0U1wjxw=";
  };

  parentPomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/sun/istack/istack-commons/3.0.8/istack-commons-3.0.8.pom";
    hash = "sha256-oPBRfoUS8PvMe4KVwS9lZqPQwthtZVY53GYu+MDH6+U=";
  };

  nativeBuildInputs = [ jdk25 ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/istack-commons/runtime/src/main/java" -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    ${jdk25}/bin/javac \
      --release 8 \
      -encoding UTF-8 \
      -cp "${jakarta_activation_api_1_2_1}/jakarta.activation-api-1.2.1.jar" \
      -d classes \
      @sources.txt

    resource_root="${finalAttrs.src}/istack-commons/runtime/src/main/resources"
    find "$resource_root" -type f | sort | while IFS= read -r path; do
      rel_path="$(realpath --relative-to="$resource_root" "$path")"
      install -Dm644 "$path" "classes/$rel_path"
    done

    (
      cd classes
      ${jdk25}/bin/jar cf "$tmp/istack-commons-runtime-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/istack-commons-runtime-${finalAttrs.version}.jar" "$out/istack-commons-runtime-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.pomFile}" "$out/istack-commons-runtime-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.parentPomFile}" "$out/istack-commons-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Common runtime classes used by JAXB components";
    homepage = "https://github.com/eclipse-ee4j/jaxb-istack-commons";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
})
