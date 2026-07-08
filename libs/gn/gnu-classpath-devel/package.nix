{
  lib,
  stdenv,
  fetchgit,
  autoconf,
  automake,
  gettext,
  texinfo,
  fastjar,
  libtool,
  pkg-config,
  ecj-bootstrap-3_2_2,
  jamvm-1_5_1,
  gnu-classpath-0_99,
}:

stdenv.mkDerivation rec {
  pname = "gnu-classpath";
  version = "0.99-1.e7c13ee0c";

  src = fetchgit {
    url = "https://git.savannah.gnu.org/git/classpath.git";
    rev = "e7c13ee0cf2005206fbec0eca677f8cf66d5a103";
    hash = "sha256-hEdXkMAcQDGK7uylusK48xk2Z1Ai6PFuFWJwbg7nWew=";
  };

  patches = [
    ../gnu-classpath-0_99/aarch64-support.patch
  ];

  nativeBuildInputs = [
    autoconf
    automake
    gettext
    texinfo
    fastjar
    libtool
    pkg-config
  ];

  preConfigure = ''
    mkdir -p bootstrap-tools

    classpathTool() {
      substitute ${../../op/openjdk-common/classpath-tool.sh.in} "bootstrap-tools/$1" \
        --subst-var-by shell "${stdenv.shell}" \
        --subst-var-by java "${jamvm-1_5_1}/bin/jamvm" \
        --subst-var-by classpath "${gnu-classpath-0_99}" \
        --subst-var-by toolPkg "$2" \
        --subst-var-by mainClass "$3"
      chmod +x "bootstrap-tools/$1"
    }

    classpathTool javah javah Main
    export PATH="$PWD/bootstrap-tools:$PATH"

    while IFS= read -r file; do
      substituteInPlace "$file" --replace-fail '@Override' ""
    done < <(grep -rl '@Override' java)

    autoreconf -vif
  '';

  configureFlags = [
    "--with-ecj-jar=${ecj-bootstrap-3_2_2}/share/java/ecj-bootstrap.jar"
    "JAVAC=${ecj-bootstrap-3_2_2}/bin/javac"
    "JAVA=${jamvm-1_5_1}/bin/jamvm"
    "GCJ_JAVAC_TRUE=no"
    "ac_cv_prog_java_works=yes"
    "--disable-Werror"
    "--disable-gmp"
    "--disable-gtk-peer"
    "--disable-gconf-peer"
    "--disable-plugin"
    "--disable-dssi"
    "--disable-alsa"
    "--disable-gjdoc"
  ];

  env = {
    CFLAGS = "-Wno-error -fpermissive -Wno-implicit-function-declaration";
    JAVAC_MEM_OPT = "-J-Xms512M -J-Xmx768M";
  };

  hardeningDisable = [ "fortify" ];

  enableParallelBuilding = true;

  postInstall = ''
    make install-data
  '';

  meta = with lib; {
    description = "Free Software Java class library development snapshot";
    homepage = "https://www.gnu.org/software/classpath/";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
