{
  mk-apk-package,
  lib,
  stdenv,
  fetchurl,
  jdk25,
  lspatch-cli,
}:
let
  appPackage =
    let
      rednoteApk = fetchurl {
        # https://xiaohongshu.cn.uptodown.com/android/dw/1032665165
        name = "xiaohongshu-8-57-0.apk";
        url = "https://web.archive.org/web/20260327124703if_/https://dw.uptodown.net/dwn/_qdwgacaxCJFCRSHvZDaV7u1ylUxV35wGSw1FsfMh7Zle1f9AxYjbaPhXlAPMHfgps6Wn8D1uiiX7UbG83Vij5BftCMEdzBoqJVZnngv-Gtru1dDs0sDNkmsmPfxFRhZ/2MXNISdtr45yC_Iq-ZegIy4zATSv8t6T9jXg5NEde_2yiRRF_L-5k0Frp-W19thLM7PM4EMwEImE7Rp60fMeyQF-T8tREjUPI1b5RqPjj9pdJzUqcBdBjfWX1yMXuL4h/iNmbuKF0IfnuwnBIqRWE5SwEkvArW0hIU8VayMMYMU_yoEU7PJTgsIh-z_oYbSMaOHhCLkIIXe52g9WTJRqy6A==/xiaohongshu-8-57-0.apk";
        hash = "sha256-kir307Tpk21QNu6zez5jWZmwScZaoc1Q11f5Gh5c/xE=";
      };
      rednoteHelper = fetchurl {
        url = "https://github.com/Xposed-Modules-Repo/com.skyhand.redbookhelper/releases/download/32-1.2.7/RednoteHelper-v1.2.7-32-20250226.apk";
        hash = "sha256-1dteIPzCMDH92sataBPzt0WP0tx2w/P/LV9zKHNF+nU=";
      };
    in
    stdenv.mkDerivation {
      pname = "rednote";
      version = "8.57.0";

      dontUnpack = true;

      nativeBuildInputs = [
        jdk25
      ];

      env = {
        JAVA_HOME = jdk25;
      };

      buildPhase = ''
        runHook preBuild

        workdir="$TMPDIR/rednote"
        mkdir -p "$workdir" "$workdir/out"

        cp "${rednoteApk}" "$workdir/rednote.apk"

        ${lib.getExe lspatch-cli} \
          --force \
          --output "$workdir/out" \
          --embed "${rednoteHelper}" \
          "$workdir/rednote.apk"

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        output_apk="$(ls "$workdir/out"/*-lspatched.apk 2>/dev/null | head -n1)"
        if [ -z "$output_apk" ]; then
          echo "No patched APK produced" >&2
          exit 1
        fi
        install -Dm644 "$output_apk" "$out/rednote.apk"
        runHook postInstall
      '';

      passthru = {
        inherit rednoteApk;
      };

      meta = with lib; {
        description = "Rednote client patched with the latest RednoteHelper Xposed module via LSPatch";
        homepage = "https://github.com/Xposed-Modules-Repo/com.skyhand.redbookhelper";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "rednote.apk";
  signScriptName = "sign-rednote";
  fdroid = {
    appId = "com.xingin.xhs";
    metadataYml = ''
      Categories:
        - Internet
      License: Proprietary
      SourceCode: https://xiaohongshu.cn.uptodown.com/android/dw/1032665165
      IssueTracker: https://xiaohongshu.cn.uptodown.com/android/dw/1032665165
      AutoName: RedNote
      Summary: Patched Xiaohongshu APK
      Description: |-
        RedNote is a patched Xiaohongshu (Little Red Book) APK built with
        LSPatch
    '';
  };
}
