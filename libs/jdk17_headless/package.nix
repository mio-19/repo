{
  callPackage,
  stdenv,
  openjdk17_headless,
}:
if stdenv.isDarwin then
  openjdk17_headless
else
  (callPackage ../openjdk-common { }).jdk17_headless_bootstrapped
