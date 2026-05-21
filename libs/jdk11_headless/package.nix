{
  callPackage,
  stdenv,
  openjdk11_headless,
}:
if stdenv.isDarwin then
  openjdk11_headless
else
  (callPackage ../openjdk-common { }).jdk11_headless_bootstrapped
