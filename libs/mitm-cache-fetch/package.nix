# based on https://github.com/NixOS/nixpkgs/blob/db956dffb8f312fcb78a24509b4944d040b575f5/pkgs/by-name/mi/mitm-cache/fetch.nix
# to see input example: nix build .#apk_amethyst.mitmCache.passthru.data
{
  lib,
  fetchurl,
  runCommand,
  writeText,
  overrides-fromsrc,
}:

let
  fileName =
    path:
    let
      parts = builtins.filter builtins.isString (builtins.split "/" path);
      n = builtins.length parts;
    in
    builtins.elemAt parts (n - 1);
  # https://repo.maven.apache.org/maven2/top/fifthlight/touchcontroller/proxy-client/0.0.4/proxy-client-0.0.4.pom -> top.fifthlight.touchcontroller:proxy-client:0.0.4
  # https://plugins.gradle.org/m2/io/grpc/grpc-context/1.57.0/grpc-context-1.57.0.jar -> io.grpc:grpc-context:1.57.0
  # https://repo.maven.apache.org/maven2/not-valid -> null
  mavenUrlToGav =
    url:
    let
      prefixes = [
        "https://repo.maven.apache.org/maven2/"
        "https://plugins.gradle.org/m2/"
        "https://cache-redirector.jetbrains.com/maven-central/"
        "https://cache-redirector.jetbrains.com/redirector.kotlinlang.org/maven/bootstrap/"
        "https://cache-redirector.jetbrains.com/redirector.kotlinlang.org/maven/kotlin-ide-plugin-dependencies/"
        "https://cache-redirector.jetbrains.com/redirector.kotlinlang.org/maven/kotlin-ide-plugin-dependencies/"
        "https://cache-redirector.jetbrains.com/packages.jetbrains.team/maven/p/plan/litmuskt/"
        "https://dl.google.com/dl/"
        "https://jitpack.io/"
        "https://redirector.kotlinlang.org/maven/kotlin-dependencies/"
      ];

      prefix = lib.findFirst (p: lib.hasPrefix p url) null prefixes;
    in
    if prefix == null then
      null
    else
      let
        rel = lib.removePrefix prefix url;
        parts = lib.splitString "/" rel;
        len = builtins.length parts;
      in
      if len < 4 then
        null
      else
        let
          fileName = builtins.elemAt parts (len - 1);
          version = builtins.elemAt parts (len - 2);
          artifactId = builtins.elemAt parts (len - 3);
          groupParts = lib.take (len - 3) parts;
          groupId = builtins.concatStringsSep "." groupParts;

          expectedPrefix = "${artifactId}-${version}";
        in
        if groupId == "" || artifactId == "" || version == "" then
          null
        else if !lib.hasPrefix expectedPrefix fileName then
          null
        else
          "${groupId}:${artifactId}:${version}";
  urlToPath =
    url:
    if lib.hasPrefix "https://" url then
      (
        let
          url' = lib.drop 2 (lib.splitString "/" url);
        in
        "https/${builtins.concatStringsSep "/" url'}"
      )
    else
      builtins.replaceStrings [ "://" ] [ "/" ] url;
in
{
  name ? "deps",
  data,
  dontFixup ? true,
  overrides ? overrides-fromsrc,
  ...
}@attrs:
let
  doOverrides =
    binary: url:
    let
      group0 = mavenUrlToGav url;
      group = if group0 == null then "__" else group0;
      file = fileName url;
      entry = (overrides."${group}" or { })."${file}" or (_: binary);
    in
    entry binary;
  data' = removeAttrs (if builtins.isPath data then lib.importJSON data else data) [
    "!version"
  ];

  code = ''
    mkdir -p "$out"
    cd "$out"
  ''
  + builtins.concatStringsSep "" (
    lib.mapAttrsToList (
      url: info:
      let
        key = builtins.head (builtins.attrNames info);
        val = info.${key};
        path = urlToPath url;
        name = baseNameOf path;
        source0 =
          {
            redirect = "$out/${urlToPath val}";
            hash = fetchurl {
              inherit url;
              hash = val;
            };
            text = writeText name val;
          }
          .${key} or (throw "Unknown key: ${url}");
        source = doOverrides source0 url;
      in
      ''
        mkdir -p "${dirOf path}"
        ln -s "${source}" "${path}"
      ''
    ) data'
  );
in
runCommand name (
  removeAttrs attrs [
    "name"
    "data"
  ]
  // {
    passthru = (attrs.passthru or { }) // {
      data = writeText "deps.json" (builtins.toJSON data);
    };
  }
) code
