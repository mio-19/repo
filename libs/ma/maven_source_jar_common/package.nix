{
  fetchurl,
  jdk25_headless,
  junit_4,
  java-hamcrest,
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
  doCheck ? (testSource != null),
  testSource ? null,
  testClass ? null,
  testClasspath ? [ ],
  disabledTests ? [ ],
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
  nativeCheckInputs = lib.optionals doCheck [
    junit_4
    java-hamcrest
  ];

  inherit doCheck;

  dontConfigure = true;
  dontUnpack = true;

  buildPhase = ''
    runHook preBuild

    tmp="$(pwd)/build-tmp"
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

    runHook postBuild
  '';

  checkPhase = lib.optionalString doCheck ''
    runHook preCheck

    test_tmp="$(pwd)/test-tmp"
    mkdir -p "$test_tmp/src" "$test_tmp/classes"
    cat << 'EOF' > "$test_tmp/src/${if testClass != null then testClass else "Test"}.java"
    ${if testSource != null then testSource else ""}
    EOF

    ${lib.concatMapStringsSep "\n" (testMethod: ''
      substituteInPlace "$test_tmp/src/${if testClass != null then testClass else "Test"}.java" \
        --replace-fail 'public void ${testMethod}()' '@org.junit.Ignore public void ${testMethod}()'
    '') disabledTests}

    javac --release ${release} -encoding ${encoding} \
      -cp "$tmp/${artifactId}-${finalAttrs.version}.jar:${junit_4}/share/java/junit.jar:${java-hamcrest}/share/java/hamcrest-3.0.jar${
        lib.optionalString (testClasspath != [ ]) ":${lib.concatStringsSep ":" testClasspath}"
      }" \
      -d "$test_tmp/classes" \
      "$test_tmp/src/${if testClass != null then testClass else "Test"}.java"

    java -cp "$test_tmp/classes:$tmp/${artifactId}-${finalAttrs.version}.jar:${junit_4}/share/java/junit.jar:${java-hamcrest}/share/java/hamcrest-3.0.jar${
      lib.optionalString (testClasspath != [ ]) ":${lib.concatStringsSep ":" testClasspath}"
    }" \
      org.junit.runner.JUnitCore ${if testClass != null then testClass else "Test"}

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

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
    sourceProvenance = with sourceTypes; [ fromSource ];
    platforms = platforms.unix;
  };
})
