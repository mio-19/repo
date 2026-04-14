{
  jdk17_headless,
  gradle-packages,
}:
(gradle-packages.mkGradle {
  version = "7.5-rc-1";
  hash = "sha256-i6V6N+HguMQV5NkXGNUQNSI6pzExz3GaUMlaKogmnrI=";
  defaultJava = jdk17_headless;
}).wrapped

# git checkout v7.5.0-RC1
# nix-shell -p javaPackages.compiler.openjdk11-bootstrap
# rm gradle/verification-metadata.xml
# patch -p1 < repository.patch
# nix run github:tadfisher/gradle2nix/6c0f9601ac41a1af04df09d8377ab706d07a4cf4  -- --gradle-wrapper=7.5-rc-1
