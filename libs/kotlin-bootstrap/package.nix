{
  ant,
  callPackage,
  fetchFromGitHub,
  fetchgit,
  fetchurl,
  jdk8,
  lib,
  makeWrapper,
  stdenv,
  unzip,
}:

let
  sources = callPackage ./sources.nix.inc { };
  sdkBuilders = callPackage ./sdk.nix.inc {
    inherit kotlin-bootstrap;
  };
  kotlinBuilders = callPackage ./compiler.nix.inc {
    inherit kotlin-bootstrap;
  };

  kotlin-bootstrap = sources.kotlin-bootstrap;

  # IntelliJ SDKs
  intellij-133 = sdkBuilders.buildIntellij { version = "133"; src = sources.intellij-133; };
  intellij-134 = sdkBuilders.buildIntellij { version = "134"; src = sources.intellij-134; };
  intellij-135 = sdkBuilders.buildIntellij { version = "135"; src = sources.intellij-135; };
  intellij-138 = sdkBuilders.buildIntellij { version = "138"; src = sources.intellij-138; };
  intellij-139 = sdkBuilders.buildIntellij { version = "139"; src = sources.intellij-139; };
  intellij-141 = sdkBuilders.buildIntellij { version = "141"; src = sources.intellij-141; };
  intellij-143 = sdkBuilders.buildIntellij { version = "143"; src = sources.intellij-143; };

in
rec {
  inherit sources;
  k0_6_786 = kotlinBuilders.buildKotlin {
    version = "0.6.786";
    src = sources.k0_6_786;
    intellijSdk = intellij-133;
  };

  k0_6_1364 = kotlinBuilders.buildKotlin {
    version = "0.6.1364";
    src = sources.k0_6_1364;
    intellijSdk = intellij-133;
    bootstrapCompiler = k0_6_786;
  };

  k0_6_1932 = kotlinBuilders.buildKotlin {
    version = "0.6.1932";
    src = sources.k0_6_1932;
    intellijSdk = intellij-133;
    bootstrapCompiler = k0_6_1364;
  };

  k0_6_2107 = kotlinBuilders.buildKotlin {
    version = "0.6.2107";
    src = sources.k0_6_2107;
    intellijSdk = intellij-133;
    bootstrapCompiler = k0_6_1932;
  };

  k0_6_2338 = kotlinBuilders.buildKotlin {
    version = "0.6.2338";
    src = sources.k0_6_2338;
    intellijSdk = intellij-133;
    bootstrapCompiler = k0_6_2107;
  };

  k0_6_2451 = kotlinBuilders.buildKotlin {
    version = "0.6.2451";
    src = sources.k0_6_2451;
    intellijSdk = intellij-134;
    bootstrapCompiler = k0_6_2338;
  };

  k0_6_2516 = kotlinBuilders.buildKotlin {
    version = "0.6.2516";
    src = sources.k0_6_2516;
    intellijSdk = intellij-134;
    bootstrapCompiler = k0_6_2451;
  };

  k0_7_333 = kotlinBuilders.buildKotlin {
    version = "0.7.333";
    src = sources.k0_7_333;
    intellijSdk = intellij-134;
    bootstrapCompiler = k0_6_2516;
  };

  k0_7_638 = kotlinBuilders.buildKotlin {
    version = "0.7.638";
    src = sources.k0_7_638;
    intellijSdk = intellij-134;
    bootstrapCompiler = k0_7_333;
  };

  k0_7_1214 = kotlinBuilders.buildKotlin {
    version = "0.7.1214";
    src = sources.k0_7_1214;
    intellijSdk = intellij-135;
    bootstrapCompiler = k0_7_638;
  };

  k0_8_84 = kotlinBuilders.buildKotlin {
    version = "0.8.84";
    src = sources.k0_8_84;
    intellijSdk = intellij-135;
    bootstrapCompiler = k0_7_1214;
  };

  k0_8_409 = kotlinBuilders.buildKotlin {
    version = "0.8.409";
    src = sources.k0_8_409;
    intellijSdk = intellij-138;
    bootstrapCompiler = k0_8_84;
  };

  k0_8_418 = kotlinBuilders.buildKotlin {
    version = "0.8.418";
    src = sources.k0_8_418;
    intellijSdk = intellij-138;
    bootstrapCompiler = k0_8_409;
  };

  k0_8_422 = kotlinBuilders.buildKotlin {
    version = "0.8.422";
    src = sources.k0_8_422;
    intellijSdk = intellij-138;
    bootstrapCompiler = k0_8_418;
  };

  k0_8_1444 = kotlinBuilders.buildKotlin {
    version = "0.8.1444";
    src = sources.k0_8_1444;
    intellijSdk = intellij-138;
    bootstrapCompiler = k0_8_422;
  };

  k0_9_21 = kotlinBuilders.buildKotlin {
    version = "0.9.21";
    src = sources.k0_9_21;
    intellijSdk = intellij-138;
    bootstrapCompiler = k0_8_1444;
  };

  k0_9_738 = kotlinBuilders.buildKotlin {
    version = "0.9.738";
    src = sources.k0_9_738;
    intellijSdk = intellij-138;
    bootstrapCompiler = k0_9_21;
  };

  k0_9_1204 = kotlinBuilders.buildKotlin {
    version = "0.9.1204";
    src = sources.k0_9_1204;
    intellijSdk = intellij-138;
    bootstrapCompiler = k0_9_738;
  };

  k0_10_300 = kotlinBuilders.buildKotlin {
    version = "0.10.300";
    src = sources.k0_10_300;
    intellijSdk = intellij-138;
    bootstrapCompiler = k0_9_1204;
  };

  k0_10_823 = kotlinBuilders.buildKotlin {
    version = "0.10.823";
    src = sources.k0_10_823;
    intellijSdk = intellij-138;
    bootstrapCompiler = k0_10_300;
  };

  k0_10_1023 = kotlinBuilders.buildKotlin {
    version = "0.10.1023";
    src = sources.k0_10_1023;
    intellijSdk = intellij-139;
    bootstrapCompiler = k0_10_823;
  };

  k0_10_1336 = kotlinBuilders.buildKotlin {
    version = "0.10.1336";
    src = sources.k0_10_1336;
    intellijSdk = intellij-141;
    bootstrapCompiler = k0_10_1023;
  };

  k0_10_1426 = kotlinBuilders.buildKotlin {
    version = "0.10.1426";
    src = sources.k0_10_1426;
    intellijSdk = intellij-141;
    bootstrapCompiler = k0_10_1336;
  };

  k0_11_153 = kotlinBuilders.buildKotlin {
    version = "0.11.153";
    src = sources.k0_11_153;
    intellijSdk = intellij-141;
    bootstrapCompiler = k0_10_1426;
  };

  k0_11_873 = kotlinBuilders.buildKotlin {
    version = "0.11.873";
    src = sources.k0_11_873;
    intellijSdk = intellij-141;
    bootstrapCompiler = k0_11_153;
  };

  k0_11_992 = kotlinBuilders.buildKotlin {
    version = "0.11.992";
    src = sources.k0_11_992;
    intellijSdk = intellij-141;
    bootstrapCompiler = k0_11_873;
  };

  k0_11_1014 = kotlinBuilders.buildKotlin {
    version = "0.11.1014";
    src = sources.k0_11_1014;
    intellijSdk = intellij-141;
    bootstrapCompiler = k0_11_992;
  };

  k0_11_1201 = kotlinBuilders.buildKotlin {
    version = "0.11.1201";
    src = sources.k0_11_1201;
    intellijSdk = intellij-141;
    bootstrapCompiler = k0_11_1014;
  };

  k0_11_1393 = kotlinBuilders.buildKotlin {
    version = "0.11.1393";
    src = sources.k0_11_1393;
    intellijSdk = intellij-141;
    bootstrapCompiler = k0_11_1201;
  };

  k0_12_108 = kotlinBuilders.buildKotlin {
    version = "0.12.108";
    src = sources.k0_12_108;
    intellijSdk = intellij-141;
    bootstrapCompiler = k0_11_1393;
  };

  k0_12_115 = kotlinBuilders.buildKotlin {
    version = "0.12.115";
    src = sources.k0_12_115;
    intellijSdk = intellij-141;
    bootstrapCompiler = k0_12_108;
  };

  k0_12_176 = kotlinBuilders.buildKotlin {
    version = "0.12.176";
    src = sources.k0_12_176;
    intellijSdk = intellij-141;
    bootstrapCompiler = k0_12_115;
  };

  k0_12_470 = kotlinBuilders.buildKotlin {
    version = "0.12.470";
    src = sources.k0_12_470;
    intellijSdk = intellij-141;
    bootstrapCompiler = k0_12_176;
  };

  k0_12_1077 = kotlinBuilders.buildKotlin {
    version = "0.12.1077";
    src = sources.k0_12_1077;
    intellijSdk = intellij-143;
    bootstrapCompiler = k0_12_470;
  };

  k0_12_1250 = kotlinBuilders.buildKotlin {
    version = "0.12.1250";
    src = sources.k0_12_1250;
    intellijSdk = intellij-143;
    bootstrapCompiler = k0_12_1077;
  };

  k0_12_1306 = kotlinBuilders.buildKotlin {
    version = "0.12.1306";
    src = sources.k0_12_1306;
    intellijSdk = intellij-143;
    bootstrapCompiler = k0_12_1250;
  };

  k0_13_177 = kotlinBuilders.buildKotlin {
    version = "0.13.177";
    src = sources.k0_13_177;
    intellijSdk = intellij-143;
    bootstrapCompiler = k0_12_1306;
  };

  k0_13_791 = kotlinBuilders.buildKotlin {
    version = "0.13.791";
    src = sources.k0_13_791;
    intellijSdk = intellij-143;
    bootstrapCompiler = k0_13_177;
  };

  k0_13_899 = kotlinBuilders.buildKotlin {
    version = "0.13.899";
    src = sources.k0_13_899;
    intellijSdk = intellij-143;
    bootstrapCompiler = k0_13_791;
  };

  k0_13_1118 = kotlinBuilders.buildKotlin {
    version = "0.13.1118";
    src = sources.k0_13_1118;
    intellijSdk = intellij-143;
    bootstrapCompiler = k0_13_899;
  };

  k0_13_1304 = kotlinBuilders.buildKotlin {
    version = "0.13.1304";
    src = sources.k0_13_1304;
    intellijSdk = intellij-143;
    bootstrapCompiler = k0_13_1118;
  };

  k0_14_209 = kotlinBuilders.buildKotlin {
    version = "0.14.209";
    src = sources.k0_14_209;
    intellijSdk = intellij-143;
    bootstrapCompiler = k0_13_1304;
  };

  k0_14_398 = kotlinBuilders.buildKotlin {
    version = "0.14.398";
    src = sources.k0_14_398;
    intellijSdk = intellij-143;
    bootstrapCompiler = k0_14_209;
  };

  k0_15_8 = kotlinBuilders.buildKotlin {
    version = "0.15.8";
    src = sources.k0_15_8;
    intellijSdk = intellij-143;
    bootstrapCompiler = k0_14_398;
  };

  k0_15_394 = kotlinBuilders.buildKotlin {
    version = "0.15.394";
    src = sources.k0_15_394;
    intellijSdk = intellij-143;
    bootstrapCompiler = k0_15_8;
  };

  k0_15_541 = kotlinBuilders.buildKotlin {
    version = "0.15.541";
    src = sources.k0_15_541;
    intellijSdk = intellij-143;
    bootstrapCompiler = k0_15_394;
  };

  k0_15_604 = kotlinBuilders.buildKotlin {
    version = "0.15.604";
    src = sources.k0_15_604;
    intellijSdk = intellij-143;
    bootstrapCompiler = k0_15_541;
  };

  k0_15_723 = kotlinBuilders.buildKotlin {
    version = "0.15.723";
    src = sources.k0_15_723;
    intellijSdk = intellij-143;
    bootstrapCompiler = k0_15_604;
  };

  k1_0_0_beta_2055 = kotlinBuilders.buildKotlin {
    version = "1.0.0-beta-2055";
    src = sources.k1_0_0_beta_2055;
    intellijSdk = intellij-143;
    bootstrapCompiler = k0_15_723;
  };

  k1_0_0_beta_3070 = kotlinBuilders.buildKotlin {
    version = "1.0.0-beta-3070";
    src = sources.k1_0_0_beta_3070;
    intellijSdk = intellij-143;
    bootstrapCompiler = k1_0_0_beta_2055;
  };

  k1_0_0_beta_4091 = kotlinBuilders.buildKotlin {
    version = "1.0.0-beta-4091";
    src = sources.k1_0_0_beta_4091;
    intellijSdk = intellij-143;
    bootstrapCompiler = k1_0_0_beta_3070;
  };

  k1_0_0_beta_5010 = kotlinBuilders.buildKotlin {
    version = "1.0.0-beta-5010";
    src = sources.k1_0_0_beta_5010;
    intellijSdk = intellij-143;
    bootstrapCompiler = k1_0_0_beta_4091;
  };

  k1_0_0_beta_5604 = kotlinBuilders.buildKotlin {
    version = "1.0.0-beta-5604";
    src = sources.k1_0_0_beta_5604;
    intellijSdk = intellij-143;
    bootstrapCompiler = k1_0_0_beta_5010;
  };

  k1_0_0_dev_162 = kotlinBuilders.buildKotlin {
    version = "1.0.0-dev-162";
    src = sources.k1_0_0_dev_162;
    intellijSdk = intellij-143;
    bootstrapCompiler = k1_0_0_beta_5604;
  };

  k1_0_0 = kotlinBuilders.buildKotlin {
    version = "1.0.0";
    src = sources.k1_0_0;
    intellijSdk = intellij-143;
    bootstrapCompiler = k1_0_0_dev_162;
  };
}
