{
  fetchFromGitHub,
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "checker-qual";
  version = "2.5.8";

  src = fetchFromGitHub {
    owner = "typetools";
    repo = "checker-framework";
    tag = "checker-framework-${finalAttrs.version}";
    hash = "sha256-OgXR8AQRdt240hYMPUsR/W7Tz4fV72MKmYivoFM1rjk=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/checkerframework/checker-qual/${finalAttrs.version}/checker-qual-${finalAttrs.version}.pom";
    hash = "sha256-M6xqDxNBrpZkfH1EZfSqPST+l9Jpe87izq5vyLXvLDw=";
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  # In 2.5.x the checker-qual jar has no sources of its own; the Gradle
  # `copySources` task assembles it from the checker/, dataflow/ and
  # framework/ projects using the include patterns replicated below.
  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"

    cd "$tmp"

    : > sources.txt
    for root in checker dataflow framework; do
      base="${finalAttrs.src}/$root/src/main/java"
      [ -d "$base" ] || continue
      while IFS= read -r f; do
        rel="''${f#"$base"/}"
        case "$rel" in
          *FormatUtil.java | *NullnessUtil.java | *RegexUtil.java | *UnitsTools.java \
          | *SignednessUtil.java | *I18nFormatUtil.java | *Opt.java | *PurityUnqualified.java \
          | org/checkerframework/*/qual/*.java | org/checkerframework/*qual/*.java)
            echo "$f" >> sources.txt
            ;;
        esac
      done < <(find "$base" -type f -name '*.java' ! -name 'module-info.java' | sort)
    done
    sort -u sources.txt -o sources.txt

    mkdir -p classes
    javac --release 8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/checker-qual-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/checker-qual-${finalAttrs.version}.jar" "$out/checker-qual-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/checker-qual-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Checker Framework annotations";
    homepage = "https://checkerframework.org/";
    license = licenses.gpl2Only;
    platforms = platforms.unix;
  };
})
