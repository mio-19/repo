{
  lib,
  stdenv,
  fetchurl,
  fetchpatch,
  gnu-classpath-0_93,
  zlib,
  libffi,
  autoconf,
  automake,
  libtool,
  zip,
}:
stdenv.mkDerivation rec {
  pname = "jamvm";
  version = "1.5.1";

  src = fetchurl {
    url = "mirror://sourceforge/jamvm/jamvm/JamVM%20${version}/jamvm-${version}.tar.gz";
    sha256 = "06lhi03l3b0h48pc7x58bk9my2nrcf1flpmglvys3wyad6yraf36";
  };

  patches = [
    ./fix-buffer-overflow.patch
    ./aarch64-support.patch
    ./armv7-support.patch
  ];

  buildInputs = [
    zlib
    libffi
    gnu-classpath-0_93
  ];

  nativeBuildInputs = [
    autoconf
    automake
    libtool
    zip
  ];

  preConfigure = ''
    autoreconf -vif
  '';

  configureFlags = [
    "--with-classpath-install-dir=${gnu-classpath-0_93}"
    "--disable-int-caching"
    "--enable-runtime-reloc-checks"
    "--enable-ffi"
  ];

  # JamVM 1.5.1 is old, might need some fixes for modern GCC
  env = {
    CFLAGS = "-O1 -Wno-error -fcommon -D_GNU_SOURCE -Wno-implicit-function-declaration -Wno-incompatible-pointer-types";
  };

  hardeningDisable = [ "fortify" ];

  meta = with lib; {
    description = "A compact Java Virtual Machine";
    homepage = "http://jamvm.sourceforge.net/";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };

  passthru = {
    home = "${placeholder "out"}";
  };
}
