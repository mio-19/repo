{
  callPackage,
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  ant_1_9_6,
  commons_cli_1_2,
  commons_io_2_2,
  gson_2_2_4,
  gzip,
  gradle-packages,
  gradle_2_0,
  jdk8_headless,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  buildMavenRepository,
  slf4j_1_7_10,
  which,
  unzip,
}:
let
  version = "2.14.1";
  gradleModules = [
    "gradle-base-services"
    "gradle-base-services-groovy"
    "gradle-cli"
    "gradle-core"
    "gradle-docs"
    "gradle-logging"
    "gradle-messaging"
    "gradle-model-core"
    "gradle-model-groovy"
    "gradle-native"
    "gradle-open-api"
    "gradle-process-services"
    "gradle-resources"
    "gradle-tooling-api"
    "gradle-ui"
    "gradle-wrapper"
  ];
  pluginModules = [
    "gradle-announce"
    "gradle-build-comparison"
    "gradle-build-init"
    "gradle-dependency-management"
    "gradle-diagnostics"
    "gradle-ear"
    "gradle-ivy"
    "gradle-jacoco"
    "gradle-javascript"
    "gradle-jetty"
    "gradle-language-groovy"
    "gradle-language-java"
    "gradle-language-jvm"
    "gradle-language-native"
    "gradle-maven"
    "gradle-osgi"
    "gradle-platform-base"
    "gradle-platform-jvm"
    "gradle-platform-native"
    "gradle-plugin-development"
    "gradle-plugin-use"
    "gradle-plugins"
    "gradle-publish"
    "gradle-reporting"
    "gradle-resources-http"
    "gradle-resources-s3"
    "gradle-resources-sftp"
    "gradle-testing-base"
    "gradle-testing-jvm"
    "gradle-testing-native"
    "gradle-tooling-api-builders"
  ];
  gradlePluginsPropertyModules = pluginModules ++ [
    "gradle-wrapper"
  ];
  runtimeSubprojects = [
    "base-services"
    "base-services-groovy"
    "cli"
    "core"
    "installation-beacon"
    "jvm-services"
    "launcher"
    "logging"
    "messaging"
    "model-core"
    "model-groovy"
    "native"
    "open-api"
    "process-services"
    "resources"
    "tooling-api"
    "ui"
    "wrapper"
  ];
  pluginSubprojects = [
    "announce"
    "build-comparison"
    "build-init"
    "dependency-management"
    "diagnostics"
    "ear"
    "ivy"
    "jacoco"
    "javascript"
    "jetty"
    "language-groovy"
    "language-java"
    "language-jvm"
    "language-native"
    "maven"
    "osgi"
    "platform-base"
    "platform-jvm"
    "platform-native"
    "plugin-development"
    "plugin-use"
    "plugins"
    "publish"
    "reporting"
    "resources-http"
    "resources-s3"
    "resources-sftp"
    "testing-base"
    "testing-jvm"
    "testing-native"
    "tooling-api-builders"
  ];
  getLayout =
    url:
    let
      prefixes = [
        "https://repo1.maven.org/maven2/"
      ];

      hasPrefix = prefix: s: builtins.substring 0 (builtins.stringLength prefix) s == prefix;

      matching = builtins.filter (p: hasPrefix p url) prefixes;
    in
    if matching == [ ] then
      throw "not a recognized Maven Central URL: ${url}"
    else
      let
        prefix = builtins.head matching;
        start = builtins.stringLength prefix;
        len = builtins.stringLength url - start;
      in
      builtins.substring start len url;
  pathMap = x: if lib.hasPrefix "lib/" x then x else "lib/" + baseNameOf x;
  bootstrapOverrides = buildMavenRepository {
    dependencies = builtins.listToAttrs (
      map (artifact: {
        name = artifact.name;
        value =
          let
            url =
              if builtins.isAttrs artifact.path && !lib.hasInfix "plugins/" artifact.name then
                artifact.path.url
              else
                "https://repo1.maven.org/maven2/" + artifact.name;
            layout = getLayout url;
          in
          assert lib.assertMsg (
            pathMap layout == artifact.name
          ) "Layout path mismatch for ${artifact.name} ${layout} ${pathMap layout}";
          {
            layout = layout;
            url = artifact.url or null;
            hash = artifact.hash or lib.fakeHash;
          }
          // lib.optionalAttrs (artifact ? path) {
            package = artifact.path;
          };
      }) dependencies
    );
    pathMap = pathMap;
  };
  dependencies = [
    {
      name = "lib/ant-1.9.6.jar";
      path = "${ant_1_9_6}/share/ant/lib/ant.jar";
    }
    {
      name = "lib/ant-launcher-1.9.6.jar";
      path = "${ant_1_9_6}/share/ant/lib/ant-launcher.jar";
    }
    {
      name = "lib/asm-all-5.1.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/ow2/asm/asm-all/5.1/asm-all-5.1.jar";
        hash = "sha256-efI+4Nihmo85WlgVLrBLwrGmN2yg7uUaPAU8mZ+1yHg=";
      };
    }
    {
      name = "lib/commons-collections-3.2.2.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/commons-collections/commons-collections/3.2.2/commons-collections-3.2.2.jar";
        hash = "sha256-7urpF5FxRKaKdB1MDf9mqlxcX9hVk/8he87T/Iyng7g=";
      };
    }
    {
      name = "lib/commons-io-2.2.jar";
      path = "${commons_io_2_2}/commons-io-2.2.jar";
    }
    {
      name = "lib/groovy-all-2.4.4.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/codehaus/groovy/groovy-all/2.4.4/groovy-all-2.4.4.jar";
        hash = "sha256-oVWgO+xAp0Gbvxj9guDU/Q/sBSiVgckNWOxQG4pfBAU=";
      };
    }
    {
      name = "lib/slf4j-api-1.7.10.jar";
      path = "${slf4j_1_7_10}/slf4j-api-1.7.10.jar";
    }
    {
      name = "lib/jcl-over-slf4j-1.7.10.jar";
      path = "${slf4j_1_7_10}/jcl-over-slf4j-1.7.10.jar";
    }
    {
      name = "lib/jul-to-slf4j-1.7.10.jar";
      path = "${slf4j_1_7_10}/jul-to-slf4j-1.7.10.jar";
    }
    {
      name = "lib/log4j-over-slf4j-1.7.10.jar";
      path = "${slf4j_1_7_10}/log4j-over-slf4j-1.7.10.jar";
    }
    {
      name = "lib/minlog-1.2.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/com/esotericsoftware/minlog/minlog/1.2/minlog-1.2.jar";
        hash = "sha256-pnjLGqj10D2QHJksdXQYQdmKm8PVXa0C6E1lMVxOYPI=";
      };
    }
    {
      name = "lib/bndlib-2.4.0.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/biz/aQute/bnd/bndlib/2.4.0/bndlib-2.4.0.jar";
        hash = "sha256-cswrlX95qUfhCwfi4iNstd5AZ31KuCrDMiRYanQ6P4Q=";
      };
    }
    {
      name = "lib/httpclient-4.4.1.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/apache/httpcomponents/httpclient/4.4.1/httpclient-4.4.1.jar";
        hash = "sha256-spWP+3T2keEIq+aa8AAsz/kLoyZCBZaxqrW7D2PDHvk=";
      };
    }
    {
      name = "lib/httpcore-4.4.4.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/apache/httpcomponents/httpcore/4.4.4/httpcore-4.4.4.jar";
        hash = "sha256-97wJ3IpwA4ItEJY0/9OEXVedEuclrlRnPjI6fOf14yU=";
      };
    }
    {
      name = "lib/wagon-provider-api-2.4.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/apache/maven/wagon/wagon-provider-api/2.4/wagon-provider-api-2.4.jar";
        hash = "sha256-9l2NWdcbyhj/olm1pt5naXvGW5/xFCx7tEF6tLHKzZI=";
      };
    }
    {
      name = "lib/wagon-file-2.4.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/apache/maven/wagon/wagon-file/2.4/wagon-file-2.4.jar";
        hash = "sha256-nEPoehcJnrKgIEiQXU0eh5yvwOPllWMyCBvSf+x8y4U=";
      };
    }
    {
      name = "lib/wagon-http-2.4.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/apache/maven/wagon/wagon-http/2.4/wagon-http-2.4.jar";
        hash = "sha256-Kuwiu+f0IKLa2qH+cZjcALFJj+2HABYdTj/Hj96H73Q=";
      };
    }
    {
      name = "lib/wagon-http-shared4-2.4.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/apache/maven/wagon/wagon-http-shared4/2.4/wagon-http-shared4-2.4.jar";
        hash = "sha256-jZ2ANpgRV1cWpjisQaYY5a2RXuP5iJDmHgOhf3g9EOs=";
      };
    }
    {
      name = "lib/aether-connector-wagon-1.13.1.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/sonatype/aether/aether-connector-wagon/1.13.1/aether-connector-wagon-1.13.1.jar";
        hash = "sha256-31ToUFEEIo7n4/verXp6nLdTsEymyc9gprGa7gc38ew=";
      };
    }
    {
      name = "lib/joda-time-2.8.2.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/joda-time/joda-time/2.8.2/joda-time-2.8.2.jar";
        hash = "sha256-fHGse0wOa35JvMk8E1gl0j9CerpiOXsxPH/c0sGcQss=";
      };
    }
    {
      name = "lib/aws-java-sdk-s3-1.9.19.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-s3/1.9.19/aws-java-sdk-s3-1.9.19.jar";
        hash = "sha256-Y6BiWIgu1rSI+iyn0+hM8YcSEqZxbdCIrJkmwVAR0tw=";
      };
    }
    {
      name = "lib/aws-java-sdk-kms-1.9.19.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-kms/1.9.19/aws-java-sdk-kms-1.9.19.jar";
        hash = "sha256-B1jMMvikKPBzPpWsWKmbb8RG9DT9BwHmdqSkGihLX1s=";
      };
    }
    {
      name = "lib/aws-java-sdk-core-1.9.19.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-core/1.9.19/aws-java-sdk-core-1.9.19.jar";
        hash = "sha256-kpGjGTmut+YdoYEJXmjO20NxD/DZ35qMCfrWglaxS3s=";
      };
    }
    {
      name = "lib/jackson-core-2.3.2.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-core/2.3.2/jackson-core-2.3.2.jar";
        hash = "sha256-aCyaQbJfVX4fKhiEbCxA4aQdrsGRZP/cz+xa2DErc9o=";
      };
    }
    {
      name = "lib/jackson-annotations-2.3.2.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-annotations/2.3.2/jackson-annotations-2.3.2.jar";
        hash = "sha256-H56/khp4CoVNXaFj3edqZ3SortTK5WYA3VY7ZRhs9g0=";
      };
    }
    {
      name = "lib/jackson-databind-2.3.2.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-databind/2.3.2/jackson-databind-2.3.2.jar";
        hash = "sha256-pHaEbpBSQo1SjQxA1QjsHb/RxiV0NNFWRcF3JOWR93U=";
      };
    }
    {
      name = "lib/plugins/commons-cli-1.2.jar";
      path = "${commons_cli_1_2}/commons-cli-1.2.jar";
    }
    {
      name = "lib/plugins/httpclient-4.4.1.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/apache/httpcomponents/httpclient/4.4.1/httpclient-4.4.1.jar";
        hash = "sha256-spWP+3T2keEIq+aa8AAsz/kLoyZCBZaxqrW7D2PDHvk=";
      };
    }
    {
      name = "lib/plugins/httpcore-4.4.4.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/apache/httpcomponents/httpcore/4.4.4/httpcore-4.4.4.jar";
        hash = "sha256-97wJ3IpwA4ItEJY0/9OEXVedEuclrlRnPjI6fOf14yU=";
      };
    }
    {
      name = "lib/plugins/junit-4.12.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/junit/junit/4.12/junit-4.12.jar";
        hash = "sha256-WXIfCAXiI9hLkGd4h9n/Vn3FNNfFAsqQPAwrF/BcEWo=";
      };
    }
    {
      name = "lib/plugins/testng-6.3.1.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/testng/testng/6.3.1/testng-6.3.1.jar";
        hash = "sha256-V+2Og+NXw4ONqtgbeJonUyJ/7oz7hqoxpht2XECT1q0=";
      };
    }
    {
      name = "lib/plugins/jcommander-1.12.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/com/beust/jcommander/1.12/jcommander-1.12.jar";
        hash = "sha256-R1RLLOOhbYi8/cIUQgDeXRqfJtzyGpKQla5i2InGYUs=";
      };
    }
    {
      name = "lib/plugins/hamcrest-core-1.3.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/hamcrest/hamcrest-core/1.3/hamcrest-core-1.3.jar";
        hash = "sha256-Zv3vkelzk0jfeglqo4SlaF9Oh1WEzOiThqekclHE2Ok=";
      };
    }
    {
      name = "lib/plugins/jsch-0.1.53.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/com/jcraft/jsch/0.1.53/jsch-0.1.53.jar";
        hash = "sha256-8A1csp1wqY72vyAA7cibQVrm9Z0l4zyvVXiyDQ1ACTI=";
      };
    }
    {
      name = "lib/plugins/wagon-provider-api-2.4.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/apache/maven/wagon/wagon-provider-api/2.4/wagon-provider-api-2.4.jar";
        hash = "sha256-9l2NWdcbyhj/olm1pt5naXvGW5/xFCx7tEF6tLHKzZI=";
      };
    }
    {
      name = "lib/plugins/jetty-6.1.25.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/mortbay/jetty/jetty/6.1.25/jetty-6.1.25.jar";
        hash = "sha256-cgnXAf8d/AkGgY9pXWsh/KeXI4XeBW1tUyYDgGROQ1g=";
      };
    }
    {
      name = "lib/plugins/jetty-util-6.1.25.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/mortbay/jetty/jetty-util/6.1.25/jetty-util-6.1.25.jar";
        hash = "sha256-qHONvxGQLAvnxmwEPT2ZrltLZELz/Eky3lf2CDX4gQM=";
      };
    }
    {
      name = "lib/plugins/jetty-plus-6.1.25.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/mortbay/jetty/jetty-plus/6.1.25/jetty-plus-6.1.25.jar";
        hash = "sha256-VRxEclsW0zDn78D9y8rmSwEeokR8W5iu+XLAWrqOqLI=";
      };
    }
    {
      name = "lib/plugins/jetty-naming-6.1.25.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/mortbay/jetty/jetty-naming/6.1.25/jetty-naming-6.1.25.jar";
        hash = "sha256-CNO6iiQ1ZSm2FgqHLhEJen8oON5+TpLyEruJ/3gl7Ds=";
      };
    }
    {
      name = "lib/plugins/jetty-annotations-6.1.25.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/mortbay/jetty/jetty-annotations/6.1.25/jetty-annotations-6.1.25.jar";
        hash = "sha256-K1An15QJfS0pD2/ANSRfC2Z6528X4t9xRbw5iubb35M=";
      };
    }
    {
      name = "lib/plugins/rhino-1.7R3.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/mozilla/rhino/1.7R3/rhino-1.7R3.jar";
        hash = "sha256-VPBEsFRyYEK6OeERbQqak9zDs/OQp5mGpiUdi7IWfm0=";
      };
    }
    {
      name = "lib/plugins/simple-4.1.21.jar";
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/org/simpleframework/simple/4.1.21/simple-4.1.21.jar";
        hash = "sha256-jmQ5/MHy/oe138IOsTKJrLqAR+nPrfRa09xcV6m80FQ=";
      };
    }
    {
      name = "lib/plugins/gson-2.2.4.jar";
      path = "${gson_2_2_4}/gson-2.2.4.jar";
    }
  ];
  defaultImportsTxtGzB64 = ''
    H4sICGfU2GkAA2RlZmF1bHQtaW1wb3J0cy50eHQAlZhJltsgEIb3OUXWWfhOCGG53BhoBjmd0wcka7KporTo1++ZD2rkBwEPZ338bf1wGbzotbr8+QUfvwkH6O/CR7gKGQODkELecAs7zmbAKBMZbB80g4Lxh0E9xKgMg/tOynPW88rZANF6UJz0eBWSxmNuZ0V61edxEBo310OIHroUweKhHiCn0wCGWJGogPqrJG3qCkTTgYESDfwT5BpvGOUQmNFKerW7GEWuirzBSJRN2yFnZWiOS2uuMCRP22zleBkXxthkJJ6xDYzaN6kuge5LXwkPIbvX0IBl2l3FiPf/Qtkw4LKxQN8p142xWJBCizZljWhHPVMP2yu8T1zqNIRbc5wSlj3TLPCOjSJ8tUlarI4U1/pM8+y31izil6WN2CIbsUobZ7leOWWyzklKVTecrvPGteMJNnlJ2AxOSXyUzuo8KghxfxHOaWgI2Ex2yfSaSv+MldRTEjxTPYjB2BChGSCYfAo9cikFnvSZLDrbW9mg6I0/M1EFstGO1D3l44LJlv/NhfMB14r16XPhFCJNKd7KqU1V9YjcYnRVbtLzchqS3bxReE+qv1F5k2tIVQl6dZF9PZfLGG6iECOEfACEmHqwPIgK7AMmjCO6fR8f6O/7vRekB4fI1TuLe1FIp0W8Wo+bpSIu4/Tyi2zUj+KJyD2OD1qr5U1AvS+1MEMSQ27QENSj00iHVzAqqAqOx7jCnQh1FTsSy3WbgbJ8nEjqZFjJ+h7aDbPsSU4upL1elZp7tEG6upIcAJ5jGWS4Nt2u2wSvTBPK8m4ime5x8obpxAHgeUZu4RUzWUtGRYoFxjJWt91dyTKp0aQ7jhXcjj/lRasrD+RJT3h96huZ8MwMeFbk3qbY0g/8JvSGsPyaUYZrL5B3DsQn+PpdCP9cwS/ojJ5/Q86xeJrYO+gdxM7SGifRiyhOn3F6m3XO/8HaQatToeymnPXwLM+PhWxZFKb8WXH0snEkOjACeSk8gvTb3pFtOIia+2m//U0UuYdeRMODBSgXchTCCzkPk+WbLVx6NSLa8QLWJ1gsLROV0GrOcSjkVWk/3r/uW5ZGS0qw2/ieUVKDa7hVuPxXPxTWx7rtRkN07QfbvEJW5igz3rGKInDn7TMgnw3oJPT7l54R8gTkpaMy8R5ugO7HD9pnuP4Fi8JP678akQcYDPaw8c6U/6LR6DXaDXQulxnxx9G5O4Doqt7mD6V6k8zvsj4Zg6TlAFAidABxnVleedB9cQAog+vbkpBW0o8Ubyjt3Vc+vImEvF6e/gN+hoeZxhsAAA==
  '';
  apiMappingTxtGzB64 = ''
    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
  '';

  mkGradle' =
    {
      ...
    }:
    stdenv.mkDerivation {
      pname = "gradle";
      inherit version;

      passthru = {
        bootstrapGradle = gradle_2_0;
        jdk = jdk8_headless;
      };

      src = fetchFromGitHub {
        owner = "gradle";
        repo = "gradle";
        tag = "v2.14.1";
        hash = "sha256-oyqnZ0dpejToxwLagrebTJVQv4X0tJPXK+lsybks9DQ=";
      };

      nativeBuildInputs = [
        gzip
        jdk8_headless
        unzip
      ];

      patches = [ ./gradle-2.14.1-direct-bootstrap.patch ];

      dontConfigure = true;

      buildPhase = ''
          runHook preBuild

          export JAVA_HOME=${jdk8_headless}
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME" build/lib build/runtime/classes build/plugins/classes build/bootstrap build/meta

          cp -a ${gradle_2_0}/libexec/gradle/. build/bootstrap/gradle-${version}/
          chmod -R u+w build/bootstrap/gradle-${version}
          mkdir -p build/bootstrap/gradle-${version}/lib/plugins

          rm -f \
            build/bootstrap/gradle-${version}/lib/ant-*.jar \
            build/bootstrap/gradle-${version}/lib/ant-launcher-*.jar \
            build/bootstrap/gradle-${version}/lib/asm-all-*.jar \
            build/bootstrap/gradle-${version}/lib/commons-collections-*.jar \
            build/bootstrap/gradle-${version}/lib/commons-io-*.jar \
            build/bootstrap/gradle-${version}/lib/groovy-all-*.jar \
            build/bootstrap/gradle-${version}/lib/slf4j-api-*.jar \
            build/bootstrap/gradle-${version}/lib/jcl-over-slf4j-*.jar \
            build/bootstrap/gradle-${version}/lib/jul-to-slf4j-*.jar \
            build/bootstrap/gradle-${version}/lib/log4j-over-slf4j-*.jar \
            build/bootstrap/gradle-${version}/lib/minlog-*.jar \
            build/bootstrap/gradle-${version}/lib/bndlib-*.jar \
            build/bootstrap/gradle-${version}/lib/httpclient-*.jar \
            build/bootstrap/gradle-${version}/lib/httpcore-*.jar \
            build/bootstrap/gradle-${version}/lib/wagon-provider-api-*.jar \
            build/bootstrap/gradle-${version}/lib/wagon-file-*.jar \
            build/bootstrap/gradle-${version}/lib/wagon-http-*.jar \
            build/bootstrap/gradle-${version}/lib/wagon-http-shared4-*.jar \
            build/bootstrap/gradle-${version}/lib/aether-connector-wagon-*.jar \
            build/bootstrap/gradle-${version}/lib/joda-time-*.jar \
            build/bootstrap/gradle-${version}/lib/aws-java-sdk-*.jar \
            build/bootstrap/gradle-${version}/lib/jackson-core-*.jar \
            build/bootstrap/gradle-${version}/lib/jackson-annotations-*.jar \
            build/bootstrap/gradle-${version}/lib/jackson-databind-*.jar \
            build/bootstrap/gradle-${version}/lib/maven-ant-tasks-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/commons-cli-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/httpclient-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/httpcore-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/junit-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/testng-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/jcommander-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/hamcrest-core-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/jsch-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/wagon-provider-api-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/jetty-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/jetty-util-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/jetty-plus-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/jetty-naming-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/jetty-annotations-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/rhino-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/simple-*.jar \
            build/bootstrap/gradle-${version}/lib/plugins/gson-*.jar

          cp -Lr ${bootstrapOverrides}/lib/. build/bootstrap/gradle-${version}/lib/
          chmod -R u+w build/bootstrap/gradle-${version}/lib
          cp -Lr ${bootstrapOverrides}/lib/plugins/. build/bootstrap/gradle-${version}/lib/plugins/
          chmod -R u+w build/bootstrap/gradle-${version}/lib/plugins

          for jar in build/bootstrap/gradle-${version}/lib/*.jar; do
            name="$(basename "$jar")"
            if ! echo "$name" | grep -q '^gradle-'; then
              cp -n "$jar" build/bootstrap/gradle-${version}/lib/plugins/
            fi
          done

          cp build/bootstrap/gradle-${version}/lib/*.jar build/lib/
          cp build/bootstrap/gradle-${version}/lib/plugins/*.jar build/lib/
          chmod u+w build/lib/*.jar
          rm -f build/lib/gradle-*.jar

        : > build/runtime-sources.txt
        for subproject in ${lib.escapeShellArgs runtimeSubprojects}; do
          for dir in "subprojects/$subproject/src/main/java" "subprojects/$subproject/src/main/groovy"; do
            if [ -d "$dir" ]; then
              find "$dir" -type f \( -name '*.groovy' -o -name '*.java' \) | sort >> build/runtime-sources.txt
            fi
          done
        done
        sort -u build/runtime-sources.txt -o build/runtime-sources.txt

        compileClasspath="$(printf '%s:' build/lib/*.jar)''${JAVA_HOME}/lib/tools.jar"
        "''$JAVA_HOME/bin/java" -noverify -Dfile.encoding=UTF-8 -Xmx2500m -classpath "$compileClasspath" \
          org.codehaus.groovy.tools.FileSystemCompiler \
          --classpath "$compileClasspath" \
          --encoding UTF-8 \
          -j \
          -d build/runtime/classes \
          @build/runtime-sources.txt

        pluginsClasspath="build/runtime/classes:$compileClasspath"
        : > build/plugins-sources.txt
        for subproject in ${lib.escapeShellArgs pluginSubprojects}; do
          for dir in "subprojects/$subproject/src/main/java" "subprojects/$subproject/src/main/groovy"; do
            if [ -d "$dir" ]; then
              find "$dir" -type f \( -name '*.groovy' -o -name '*.java' \) | sort >> build/plugins-sources.txt
            fi
          done
        done
        sort -u build/plugins-sources.txt -o build/plugins-sources.txt
        "''$JAVA_HOME/bin/java" -noverify -Dfile.encoding=UTF-8 -Xmx2500m -classpath "$pluginsClasspath" \
          org.codehaus.groovy.tools.FileSystemCompiler \
          --classpath "$pluginsClasspath" \
          --encoding UTF-8 \
          -j \
          -d build/plugins/classes \
          @build/plugins-sources.txt

        for subproject in ${lib.escapeShellArgs runtimeSubprojects}; do
          if [ -d "subprojects/$subproject/src/main/resources" ]; then
            cp -a "subprojects/$subproject/src/main/resources/." build/runtime/classes/
          fi
        done
        for subproject in ${lib.escapeShellArgs pluginSubprojects}; do
          if [ -d "subprojects/$subproject/src/main/resources" ]; then
            cp -a "subprojects/$subproject/src/main/resources/." build/plugins/classes/
          fi
        done

        cat > build/meta/default-imports.txt.gz.b64 <<'EOF'
        ${defaultImportsTxtGzB64}
        EOF
        cat > build/meta/api-mapping.txt.gz.b64 <<'EOF'
        ${apiMappingTxtGzB64}
        EOF
        base64 -d build/meta/default-imports.txt.gz.b64 | gzip -d > build/runtime/classes/default-imports.txt
        base64 -d build/meta/api-mapping.txt.gz.b64 | gzip -d > build/runtime/classes/api-mapping.txt

        mkdir -p build/runtime/classes/META-INF/services build/plugins/classes/META-INF/services
        cat > build/runtime/classes/META-INF/services/org.gradle.internal.service.scopes.PluginServiceRegistry <<'EOF'
        org.gradle.tooling.internal.provider.LauncherServices
        EOF
        cat > build/plugins/classes/META-INF/services/org.gradle.internal.service.scopes.PluginServiceRegistry <<'EOF'
        org.gradle.buildinit.plugins.internal.BuildInitServices
        org.gradle.api.internal.artifacts.DependencyServices
        org.gradle.api.reporting.components.internal.DiagnosticsServices
        org.gradle.api.publish.ivy.internal.IvyPublishServices
        org.gradle.language.java.internal.JavaToolChainServiceRegistry
        org.gradle.language.java.internal.JavaLanguagePluginServiceRegistry
        org.gradle.language.jvm.internal.JvmPluginServiceRegistry
        org.gradle.language.nativeplatform.internal.registry.NativeLanguageServices
        org.gradle.api.publish.maven.internal.MavenPublishServices
        org.gradle.platform.base.internal.registry.ComponentModelBaseServiceRegistry
        org.gradle.jvm.internal.services.PlatformJvmServices
        org.gradle.nativeplatform.internal.services.NativeBinaryServices
        org.gradle.plugin.use.internal.PluginUsePluginServiceRegistry
        org.gradle.api.internal.tasks.CompileServices
        org.gradle.api.publish.internal.PublishServices
        org.gradle.internal.resource.transport.http.HttpResourcesPluginServiceRegistry
        org.gradle.internal.resource.transport.aws.s3.S3ResourcesPluginServiceRegistry
        org.gradle.internal.resource.transport.sftp.SftpResourcesPluginServiceRegistry
        org.gradle.jvm.test.internal.services.JvmTestingServices
        org.gradle.nativeplatform.test.internal.services.NativeTestingServices
        org.gradle.tooling.internal.provider.runner.ToolingBuilderServices
        EOF
        cat > build/plugins/classes/META-INF/services/org.gradle.api.internal.artifacts.DependencyManagementServices <<'EOF'
        org.gradle.api.internal.artifacts.DefaultDependencyManagementServices
        EOF

        mkdir -p build/runtime/classes/org/gradle
        cat > build/runtime/classes/org/gradle/build-receipt.properties <<EOF
        buildTimestamp=20160718063837+0000
        commitId=direct-bootstrap
        isSnapshot=false
        versionBase=${version}
        versionNumber=${version}
        EOF

        printf 'plugins=%s\n' "${lib.concatStringsSep "," gradlePluginsPropertyModules}" > build/runtime/classes/gradle-plugins.properties

        runtime="$(cd build/bootstrap/gradle-${version}/lib && ls *.jar | grep -v '^gradle-' | paste -sd, -)"
        pluginRuntime="$(cd build/bootstrap/gradle-${version}/lib/plugins && ls *.jar | grep -v '^gradle-' | paste -sd, -)"

        for module in ${lib.escapeShellArgs gradleModules}; do
          {
            printf 'runtime=%s\n' "$runtime"
            printf 'projects=\n'
          } > "build/runtime/classes/$module-classpath.properties"
        done
        for module in ${lib.escapeShellArgs pluginModules}; do
          {
            printf 'runtime=%s\n' "$pluginRuntime"
            printf 'projects=\n'
          } > "build/plugins/classes/$module-classpath.properties"
        done

        (
          cd build/runtime/classes
          "''$JAVA_HOME/bin/jar" cf ../gradle-runtime-${version}.jar .
        )
        (
          cd build/plugins/classes
          "''$JAVA_HOME/bin/jar" cf ../gradle-plugins-${version}.jar .
        )

          runHook postBuild
      '';

      installPhase = ''
          runHook preInstall

          gradleHome="$out/libexec/gradle"
          mkdir -p "$gradleHome/lib/plugins" "$out/bin"

        cp build/bootstrap/gradle-${version}/lib/*.jar "$gradleHome/lib/"
        cp build/bootstrap/gradle-${version}/lib/plugins/*.jar "$gradleHome/lib/plugins/"
        rm -f "$gradleHome"/lib/gradle-*.jar
        rm -f "$gradleHome"/lib/plugins/gradle-*.jar
        for module in ${lib.escapeShellArgs gradleModules}; do
          cp build/runtime/gradle-runtime-${version}.jar "$gradleHome/lib/$module-${version}.jar"
        done
        for module in ${lib.escapeShellArgs pluginModules}; do
          cp build/plugins/gradle-plugins-${version}.jar "$gradleHome/lib/plugins/$module-${version}.jar"
        done

        cat > "$out/bin/gradle" <<'EOF'
        #!${stdenv.shell}
        export JAVA_HOME="''${JAVA_HOME:-${jdk8_headless}}"
        export PATH="${
          lib.makeBinPath [
            coreutils
            findutils
            gnugrep
            gnused
            which
            jdk8_headless
          ]
        }:''$PATH"
        exec "''$JAVA_HOME/bin/java" \
          -noverify \
          -classpath "${placeholder "out"}/libexec/gradle/lib/gradle-core-${version}.jar" \
          org.gradle.launcher.GradleMain \
          "''$@"
        EOF
          chmod +x "$out/bin/gradle"

          runHook postInstall
      '';

      meta = {
        description = "Source-built Gradle ${version} bootstrap bridge";
        homepage = "https://gradle.org/";
        license = lib.licenses.asl20;
        mainProgram = "gradle";
        platforms = lib.platforms.unix;
      };
    };

  unwrapped = callPackage mkGradle' { };
in
callPackage gradle-packages.wrapGradle {
  gradle-unwrapped = unwrapped;
}
