{
  lib,
  stdenv,
  fetchurl,
}:
stdenv.mkDerivation rec {
  pname = "jikes";
  version = "1.22";

  src = fetchurl {
    url = "mirror://sourceforge/jikes/jikes-${version}.tar.bz2";
    hash = "sha256-DLAsdjvEQTSfbTjKzVKt92IwLM46COJp8fdfcm5uFOM=";
  };

  # Jikes is an older C++ project and often requires specific flags
  # to build on modern compilers.
  # --disable-fenv is often needed on non-x86 or newer systems
  configureFlags = [ "--disable-fenv" ];

  # For modern GCC
  CXXFLAGS = "-std=gnu++98 -Wno-narrowing";

  hardeningDisable = [ "fortify" ];

  meta = with lib; {
    description = "A fast Java compiler written in C++";
    homepage = "http://jikes.sourceforge.net/";
    license = licenses.ipl10;
    platforms = platforms.all;
  };
}
