{
  lib,
  stdenv,
  fetchurl,
  jdk21,
  lspatchCli,
  biliroaming,
}:
let
  bilibiliApk = fetchurl {
    # https://www.apkmirror.com/apk/bilibili/bilibili-%e5%93%94%e5%93%a9%e5%93%94%e5%93%a9/bilibili-all-your-fav-videos-8-71-0-release/bilibili-all-your-fav-videos-8-71-0-2-android-apk-download/
    name = "tv.danmaku.bili-8.71.0.apk";
    url = "https://web.archive.org/web/20260325114822if_/https://eb5e7388c3df147b74dd2379b7cf8323.r2.cloudflarestorage.com/downloadprod/wp-content/uploads/2025/11/07/691ec7d10fc45/tv.danmaku.bili_8.71.0-8710600_minAPI23%28armeabi-v7a%2Cx86%29%28nodpi%29_apkmirror.com.apk?X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=72a5ba3a0b8a601e535d5525f12f8177%2F20260325%2Fauto%2Fs3%2Faws4_request&X-Amz-Date=20260325T114811Z&X-Amz-SignedHeaders=host&X-Amz-Expires=3600&X-Amz-Signature=17fa4e48203ee87ac65361f33874bdad6acc369659c3883b70294a3871118d22";
    hash = "sha256-hvpgtJ5ZxEpSqtrVInfpOKpX8YbdMLdPYl3hrmILVEQ=";
  };

in
stdenv.mkDerivation {
  pname = "bilibili-cn";
  version = "8.71.0";

  dontUnpack = true;

  nativeBuildInputs = [
    jdk21
  ];

  env = {
    JAVA_HOME = jdk21;
  };

  buildPhase = ''
    runHook preBuild

    "${jdk21}/bin/java" -jar ${lspatchCli}/lspatch.jar \
      --force \
      --output "$workdir/out" \
      --embed "${biliroaming}/biliroaming.apk" \
      ${bilibiliApk}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    output_apk="$(ls "$workdir/out"/*-lspatched.apk 2>/dev/null | head -n1)"
    if [ -z "$output_apk" ]; then
      echo "No patched APK produced" >&2
      exit 1
    fi
    install -Dm644 "$output_apk" "$out/bilibili-cn.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Bilibili cn client patched with the latest BiliRoaming Xposed module via LSPatch";
    homepage = "https://github.com/yujincheng08/BiliRoaming";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
}
