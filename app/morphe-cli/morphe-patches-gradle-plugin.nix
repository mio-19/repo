{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle-packages,
  jdk21,
  python3,
  writableTmpDirAsHomeHook,
}:
let
  gradle =
    (gradle-packages.mkGradle {
      version = "8.14.4";
      hash = "sha256-8XcSmKcPbbWina9iN4xOGKF/wzybprFDYuDN9AYQOA0=";
      defaultJava = jdk21;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "morphe-patches-gradle-plugin";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-patches-gradle-plugin";
    rev = "v${finalAttrs.version}";
    hash = "sha256-pmw+qJcv/GTrNMdjaJjAhxJmgpVXlkY7wb6eawzNI0o=";
  };

  gradleBuildTask = "publish";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    pname = "morphe-patches-gradle-plugin";
    pkg = finalAttrs.finalPackage;
    data = ./morphe-patches-gradle-plugin_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk21
    python3
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
    GITHUB_ACTOR = "nix-build";
    GITHUB_TOKEN = "ghp_dummy";
  };

  postUnpack = ''
root="$PWD"

python3 -c '
import os, re

def patch_file(filename):
    if not os.path.exists(filename): return
    with open(filename, "r") as f: content = f.read()
    
    # 1. Replace the GitHub Packages URLs with local M2
    content = re.sub(r"https://maven.pkg.github.com/MorpheApp/[a-zA-Z0-9.-]+", "file://" + root_dir + "/build/m2", content)
    
    # 2. Remove credentials blocks
    content = re.sub(r"credentials\s*\{[^{}]*\}", "", content)
    
    # 3. Disable signing blocks
    content = re.sub(r"signing\s*\{.*?\}", "/* signing disabled */", content, flags=re.DOTALL)
    
    # 4. Disable signing in plugins block
    content = content.replace("signing", "// signing")
    
    with open(filename, "w") as f: f.write(content)

def patch_settings_plugin(filename):
    if not os.path.exists(filename): return
    with open(filename, "r") as f: content = f.read()
    
    # Replace the hardcoded GitHub URL in SettingsPlugin.kt
    content = re.sub(r"URI\(\"https://maven.pkg.github.com/MorpheApp/registry\"\)", "URI(\"file://\" + System.getenv(\"MORPHE_PLUGIN_M2\"))", content)
    
    # Remove the credentials block entirely in SettingsPlugin.kt
    # Match repository.credentials { ... }
    content = re.sub(r"repository\.credentials\s*\{.*?\}", "", content, flags=re.DOTALL)
    
    with open(filename, "w") as f: f.write(content)

root_dir = os.path.join(os.getcwd(), "source")
patch_file(os.path.join(root_dir, "build.gradle.kts"))
# Find and patch SettingsPlugin.kt
for root, dirs, files in os.walk(os.path.join(root_dir, "src/main/kotlin")):
    if "SettingsPlugin.kt" in files:
        patch_settings_plugin(os.path.join(root, "SettingsPlugin.kt"))
'
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    echo "Current directory: $PWD"
    echo "Checking for build/m2..."
    ls -R build/m2 || echo "build/m2 not found"
    if [ -d "build/m2" ]; then
      cp -a build/m2/. "$out/"
    fi
    find "$out" -name "*.pom"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Morphe Patches Gradle Plugin pre-built to local maven repo";
    homepage = "https://github.com/MorpheApp/morphe-patches-gradle-plugin";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
