{
  lib,
  stdenv,
  fetchurl,
  jikes,
  zip,
  pkg-config,
}:
stdenv.mkDerivation rec {
  pname = "gnu-classpath";
  version = "0.93";

  src = fetchurl {
    url = "mirror://gnu/classpath/classpath-${version}.tar.gz";
    sha256 = "0i99wf9xd3hw1sj2sazychb9prx8nadxh2clgvk3zlmb28v0jbfz";
  };

  nativeBuildInputs = [
    jikes
    zip
    pkg-config
  ];

  # Minimal build for bootstrapping
  configureFlags = [
    "--with-jikes"
    "--disable-Werror"
    "--disable-gtk-peer"
    "--disable-gconf-peer"
    "--disable-plugin"
    "--disable-alsa"
    "--disable-dssi"
    "--disable-qt-peer"
    "--disable-xmlj"
  ];

  env = {
    # Fix for modern GCC
    CFLAGS = "-Wno-error -fpermissive -Wno-implicit-function-declaration";
  };

  hardeningDisable = [ "fortify" ];

  meta = with lib; {
    description = "Free Software implementations of the Java standard class libraries";
    homepage = "https://www.gnu.org/software/classpath/";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
