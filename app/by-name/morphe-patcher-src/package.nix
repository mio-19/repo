{ fetchFromGitHub, applyPatches }:
applyPatches {
  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-patcher";
    rev = "v1.12.0";
    hash = "sha256-GiNZyhAMTie9t+XUPgvw70SuggYI4mLVxXwa9apGNpA=";
  };
  postPatch = ''
        patch -d . -p0 < ${./morphe-patcher.patch}
        substituteInPlace settings.gradle.kts \
          --replace-fail '//mapOf(' 'mapOf(' \
          --replace-fail '//    "ARSCLib" to "com.github.MorpheApp:arsclib",' '    "ARSCLib" to "com.github.MorpheApp:ARSCLib",' \
          --replace-fail '//).forEach { (libraryPath, libraryName) ->' ').forEach { (libraryPath, libraryName) ->' \
          --replace-fail '//    val libDir = file("../$libraryPath")' '    val libDir = file("../$libraryPath")' \
          --replace-fail '//    if (libDir.exists()) {' '    if (libDir.exists()) {' \
          --replace-fail '//        includeBuild(libDir) {' '        includeBuild(libDir) {' \
          --replace-fail '//            dependencySubstitution {' '            dependencySubstitution {' \
          --replace-fail '//                substitute(module(libraryName)).using(project(":"))' '                substitute(module(libraryName)).using(project(":"))' \
          --replace-fail '//            }' '            }' \
          --replace-fail '//        }' '        }' \
          --replace-fail '//    }' '    }' \
          --replace-fail '//}' '}'
        cat >> settings.gradle.kts <<'EOF'

    // Added by Nix build: include Apktool as composite build.
    val apktoolDir = file("../Apktool")
    if (apktoolDir.exists()) {
        includeBuild(apktoolDir) {
            dependencySubstitution {
                substitute(module("app.morphe:apktool-lib")).using(project(":brut.apktool:apktool-lib"))
                substitute(module("app.morphe:brut.j.common")).using(project(":brut.j.common"))
                substitute(module("app.morphe:brut.j.util")).using(project(":brut.j.util"))
                substitute(module("app.morphe:brut.j.dir")).using(project(":brut.j.dir"))
                substitute(module("app.morphe:brut.j.xml")).using(project(":brut.j.xml"))
            }
        }
    }
    EOF
        substituteInPlace src/main/kotlin/app/morphe/patcher/resource/coder/ArsclibResourceCoder.kt \
          --replace-fail '            originalExtractNativeLibs = manifest.isExtractNativeLibs' '            originalExtractNativeLibs = manifest.isExtractNativeLibs
                val versionNameSuffix = System.getenv("MORPHE_VERSION_NAME_SUFFIX")
                val versionName =
                    if (!versionNameSuffix.isNullOrBlank() && !manifest.versionName.endsWith(versionNameSuffix)) {
                        manifest.versionName + versionNameSuffix
                    } else {
                        manifest.versionName
                    }' \
          --replace-fail '                manifest.versionName,' '                versionName,'
  '';
}
