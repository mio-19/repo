{
  lib,
  stdenv,
  fetchurl,
  gnu-classpath-0_99,
  zlib,
}:
stdenv.mkDerivation rec {
  pname = "jamvm";
  version = "2.0.0";

  src = fetchurl {
    url = "mirror://sourceforge/jamvm/jamvm-${version}.tar.gz";
    sha256 = "1nl0zxz8y5x8gwsrm7n32bry4dx8x70p8z3s9jbdvs8avyb8whkn";
  };

  buildInputs = [
    zlib
    gnu-classpath-0_99
  ];

  configureFlags = [
    "--with-classpath-install-dir=${gnu-classpath-0_99}"
  ];

  env = {
    CFLAGS = "-O1 -Wno-error -fcommon -D_GNU_SOURCE -Wno-implicit-function-declaration -Wno-incompatible-pointer-types";
  };

  hardeningDisable = [ "fortify" ];

  meta = with lib; {
    description = "A compact Java Virtual Machine (Stage 2)";
    homepage = "http://jamvm.sourceforge.net/";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
