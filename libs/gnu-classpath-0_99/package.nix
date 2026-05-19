{
  lib,
  stdenv,
  fetchurl,
  fetchpatch,
  ecj-bootstrap-3_2_2,
  jamvm-1_5_1,
  fastjar,
  libtool,
  pkg-config,
}:
stdenv.mkDerivation rec {
  pname = "gnu-classpath";
  version = "0.99";

  src = fetchurl {
    url = "mirror://gnu/classpath/classpath-${version}.tar.gz";
    sha256 = "1j7cby4k66f1nvckm48xcmh352b1d1b33qk7l6hi7dp9i9zjjagr";
  };

  patches = [
    ./aarch64-support.patch
  ];

  nativeBuildInputs = [
    fastjar
    libtool
    pkg-config
  ];

  configureFlags = [
    "JAVAC=${ecj-bootstrap-3_2_2}/bin/javac"
    "JAVA=${jamvm-1_5_1}/bin/jamvm"
    "--with-ecj-jar=${ecj-bootstrap-3_2_2}/share/java/ecj-bootstrap.jar"
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
  };

  hardeningDisable = [ "fortify" ];

  enableParallelBuilding = true;

  postInstall = ''
    make install-data
  '';

  meta = with lib; {
    description = "Free Software implementations of the Java standard class libraries (0.99)";
    homepage = "https://www.gnu.org/software/classpath/";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
