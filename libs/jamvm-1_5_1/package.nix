{
  lib,
  stdenv,
  fetchurl,
  gnu-classpath-0_93,
  zlib,
}:
stdenv.mkDerivation rec {
  pname = "jamvm";
  version = "1.5.1";

  src = fetchurl {
    url = "mirror://sourceforge/jamvm/jamvm-${version}.tar.gz";
    sha256 = "06lhi03l3b0h48pc7x58bk9my2nrcf1flpmglvys3wyad6yraf36";
  };

  buildInputs = [
    zlib
    gnu-classpath-0_93
  ];

  configureFlags = [
    "--with-classpath-install-dir=${gnu-classpath-0_93}"
  ];

  # JamVM 1.5.1 is old, might need some fixes for modern GCC
  env = {
    CFLAGS = "-Wno-error -fcommon -D_GNU_SOURCE -Wno-implicit-function-declaration -Wno-incompatible-pointer-types";
  };

  hardeningDisable = [ "fortify" ];

  meta = with lib; {
    description = "A compact Java Virtual Machine";
    homepage = "http://jamvm.sourceforge.net/";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
