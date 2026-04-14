{
  fetchurl,
  jdk21_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "javax.servlet-api";
  version = "3.1.0";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/javax/servlet/javax.servlet-api/${finalAttrs.version}/javax.servlet-api-${finalAttrs.version}-sources.jar";
    hash = "sha256-XG1kDwHo5//bohsrdcD2Twww/R/DNyEjdQwDTLNjASo=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/javax/servlet/javax.servlet-api/${finalAttrs.version}/javax.servlet-api-${finalAttrs.version}.pom";
    hash = "sha256-sxEJ4i6j8t8a15VUMucYo13vUK5sGWmANK+ooM+ekGk=";
  };

  nativeBuildInputs = [ jdk21_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    
    cd "$tmp"
    jar xf "$src"

    mkdir -p classes
    find javax -name '*.java' | sort > sources.txt
    javac --release 8 -encoding ISO-8859-1 -d classes @sources.txt

    find javax -name '*.properties' | sort | while IFS= read -r path; do
      install -Dm644 "$path" "classes/$path"
    done

    (
      cd classes
      jar cf "$tmp/javax.servlet-api-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/javax.servlet-api-${finalAttrs.version}.jar" "$out/javax.servlet-api-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/javax.servlet-api-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Java Servlet API";
    homepage = "https://javaee.github.io/servlet-spec/";
    license = licenses.cddl;
    platforms = platforms.unix;
  };
})
