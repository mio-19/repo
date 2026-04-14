{
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:
{
  groupId,
  artifactId,
  version,
  srcHash,
  pomHash,
  release ? "8",
  encoding ? "UTF-8",
  sourceRoot ? ".",
}:

stdenv.mkDerivation (finalAttrs: {
  pname = artifactId;
  inherit version;

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/${
      builtins.replaceStrings [ "." ] [ "/" ] groupId
    }/${artifactId}/${finalAttrs.version}/${artifactId}-${finalAttrs.version}-sources.jar";
    hash = srcHash;
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/${
      builtins.replaceStrings [ "." ] [ "/" ] groupId
    }/${artifactId}/${finalAttrs.version}/${artifactId}-${finalAttrs.version}.pom";
    hash = pomHash;
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    
    mkdir -p "$tmp/src" "$tmp/classes"
    cd "$tmp/src"
    jar xf "${finalAttrs.src}"

    source_dir="$tmp/src/${sourceRoot}"
    find "$source_dir" -name '*.java' ! -name 'module-info.java' | sort > "$tmp/sources.txt"
    javac --release ${release} -encoding ${encoding} -d "$tmp/classes" @"$tmp/sources.txt"

    find "$source_dir" -type f ! -name '*.java' | sort | while IFS= read -r path; do
      rel_path="$(realpath --relative-to="$source_dir" "$path")"
      install -Dm644 "$path" "$tmp/classes/$rel_path"
    done

    (
      cd "$tmp/classes"
      jar cf "$tmp/${artifactId}-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/${artifactId}-${finalAttrs.version}.jar" "$out/${artifactId}-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.pom}" "$out/${artifactId}-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "${groupId}:${artifactId} built from Maven source jar";
    homepage = "https://repo.maven.apache.org/maven2/${
      builtins.replaceStrings [ "." ] [ "/" ] groupId
    }/${artifactId}/";
    platforms = platforms.unix;
  };
})
