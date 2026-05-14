{
  lib,
  stdenv,
  fetchurl,
  ecj-bootstrap-3_2_2,
  bootstrap-jdk-stage1,
  zip,
  pkg-config,
}:
stdenv.mkDerivation rec {
  pname = "gnu-classpath";
  version = "0.99";

  src = fetchurl {
    url = "mirror://gnu/classpath/classpath-${version}.tar.gz";
    sha256 = "1j7cby4k66f1nvckm48xcmh352b1d1b33qk7l6hi7dp9i9zjjagr";
  };

  nativeBuildInputs = [
    ecj-bootstrap-3_2_2
    bootstrap-jdk-stage1
    zip
    pkg-config
  ];

  configureFlags = [
    "--with-javac=${ecj-bootstrap-3_2_2}/bin/javac"
    "--with-java=${bootstrap-jdk-stage1}/bin/java"
    "--disable-Werror"
    "--disable-gtk-peer"
    "--disable-gconf-peer"
    "--disable-plugin"
    "--disable-alsa"
    "--disable-dssi"
    "--disable-qt-peer"
    "--disable-xmlj"
    "--disable-tools"
  ];

  env = {
    CFLAGS = "-Wno-error -fpermissive -Wno-implicit-function-declaration";
  };

  hardeningDisable = [ "fortify" ];

  meta = with lib; {
    description = "Free Software implementations of the Java standard class libraries (0.99)";
    homepage = "https://www.gnu.org/software/classpath/";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
