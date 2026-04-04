{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "nocubes_1_18_2";
  version = "1.18.2-0.5.0-dev-22cb4ee";
  dontUnpack = true;

  src = fetchurl {
    url = "https://github.com/Cadiboo/NoCubes/releases/download/1.18.2-0.5.0-dev-22cb4ee/NoCubes-1.18.2-0.5.0-dev-22cb4ee.jar";
    hash = "sha256-yRyU/3E5u1IjhXMx1dGHrN8az0iKUfF2wNxaIIWrtOg=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/minecraft-mods"
    install -Dm644 "$src" "$out/share/minecraft-mods/nocubes-1.18.2-forge.jar"

    runHook postInstall
  '';

  meta = with lib; {
    description = "NoCubes mod for Minecraft 1.18.2";
    homepage = "https://github.com/Cadiboo/NoCubes";
    license = licenses.lgpl3Only;
    platforms = platforms.unix;
  };
})
