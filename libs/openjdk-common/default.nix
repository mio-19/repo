{
  lib,
  stdenv,
  buildPackages,
  fetchFromGitHub,
  fetchpatch,
  autoPatchelfHook,
  pkg-config,
  autoconf,
  gnumake42,
  cpio,
  file,
  which,
  zip,
  unzip,
  zlib,
  cups,
  freetype,
  alsa-lib,
  libjpeg,
  giflib,
  libpng,
  lcms2,
  harfbuzz,
  libx11,
  libice,
  libxext,
  libxrender,
  libxtst,
  libxt,
  libxi,
  libxinerama,
  libxcursor,
  libxrandr,
  fontconfig,
  gtk2,
  glib,
  openjdk8,
  openjdk8_headless,
  openjdk11,
  openjdk11_headless,
  openjdk17,
  openjdk17_headless,
  openjdk21,
  openjdk21_headless,
  openjdk25,
  openjdk25_headless,
  icedtea7,
}:
let
  normalizeOpenJdkOverride =
    args:
    builtins.removeAttrs args [ "gtkSupport" ]
    // lib.optionalAttrs (args ? gtkSupport && !(args ? enableGtk)) {
      enableGtk = args.gtkSupport;
    };

  normalizeBootstrapOverride =
    args:
    builtins.removeAttrs args [
      "gtkSupport"
      "enableGtk"
    ];

  # Nixpkgs OpenJDK generic builder has a bug where it calls
  # jdk-bootstrap.override { gtkSupport = ... } but OpenJDK itself
  # expects enableGtk. Older bootstrap JDKs such as IcedTea do not expose
  # either flag, so they need a stricter wrapper that drops both.
  wrapOpenJdk =
    jdk:
    let
      wrapped = jdk // {
        override =
          args:
          if jdk ? override then wrapOpenJdk (jdk.override (normalizeOpenJdkOverride args)) else wrapped;
      };
    in
    wrapped;

  wrapBootstrapJdk =
    jdk:
    let
      wrapped = jdk // {
        override =
          args:
          if jdk ? override then
            wrapBootstrapJdk (jdk.override (normalizeBootstrapOverride args))
          else
            wrapped;
      };
    in
    wrapped;

  disableJavacServer =
    jdk:
    jdk.overrideAttrs (oldAttrs: {
      configureFlags = (oldAttrs.configureFlags or [ ]) ++ [ "--disable-javac-server" ];
    });

  withoutOpenJdkJvmFeatures =
    features: jdk:
    jdk.overrideAttrs (oldAttrs: {
      configureFlags =
        lib.filter (flag: !(lib.hasPrefix "--with-jvm-features=" flag)) (oldAttrs.configureFlags or [ ])
        ++ [
          "--with-jvm-features=zgc,${lib.concatMapStringsSep "," (feature: "-" + feature) features}"
        ];
    });

  buildOpenJdkImages =
    jdk:
    jdk.overrideAttrs (_oldAttrs: {
      buildFlags = [ "images" ];
    });

  openjdk11Source = fetchFromGitHub {
    owner = "openjdk";
    repo = "jdk11u";
    tag = "jdk-11.0.31-ga";
    hash = "sha256-sVBPsUgoyZg4vwaOJ+b0eCC1UvtIorw3Ba+vMaqdAHk=";
  };

  withOpenJdk11GaSource =
    jdk:
    jdk.overrideAttrs (oldAttrs: {
      version = "11.0.31+11";
      src = openjdk11Source;
      configureFlags =
        lib.filter (
          flag: !(lib.hasPrefix "--with-version-build=" flag) && !(lib.hasPrefix "--with-version-date=" flag)
        ) (oldAttrs.configureFlags or [ ])
        ++ [
          "--with-version-build=11"
          "--with-version-date=2026-04-21"
        ];
    });

  withOpenJdk11StableToolchain =
    jdk:
    jdk.overrideAttrs (oldAttrs: {
      depsBuildBuild = [ buildPackages.gcc13Stdenv.cc ];
      env = (oldAttrs.env or { }) // {
        NIX_CFLAGS_COMPILE = "-Wformat";
      };
    });

  openjdk11Stable =
    jdk: args: withOpenJdk11StableToolchain (withOpenJdk11GaSource (jdk.override args));

  patchJdk11BootstrapToolJavacFlags =
    jdk:
    jdk.overrideAttrs (oldAttrs: {
      postPatch = (oldAttrs.postPatch or "") + ''
        for file in \
          make/hotspot/gensrc/GensrcJvmti.gmk \
          make/hotspot/gensrc/GensrcJfr.gmk
        do
          substituteInPlace "$file" \
            --replace-fail 'FLAGS := $(DISABLE_WARNINGS), \' \
                           'FLAGS := -XDignore.symbol.file=true -XDstringConcat=inline $(DISABLE_WARNINGS), \'
        done
      '';
    });

  icedtea7_bootstrap = wrapBootstrapJdk icedtea7;

  mkOpenJdkBootstrap =
    {
      featureVersion,
      version,
      repo,
      tag,
      hash,
      bootJdk,
      headless ? false,
    }:
    let
      bootHome = bootJdk.passthru.home or bootJdk.home or "${bootJdk}";
      buildJobs = "$NIX_BUILD_CORES";
      selectBuiltJdkImage = ''
        image=
        while IFS= read -r candidate; do
          if [ -x "$candidate/bin/java" ]; then
            image="$candidate"
            break
          fi
        done < <(find build -path '*/images/jdk' -type d)
      '';
      harfbuzzIncludeFlag = lib.optionalString (lib.versionAtLeast featureVersion "23") " -I${lib.getDev harfbuzz}/include/harfbuzz";
      bootstrapConfigureFlags = [
        "--with-boot-jdk=${bootHome}"
        "--with-extra-cflags=-fcommon -fno-delete-null-pointer-checks -fno-lifetime-dse -std=gnu17 -Wno-error=int-conversion -Wno-error=incompatible-pointer-types${harfbuzzIncludeFlag}"
        "--with-freetype-include=${lib.getDev freetype}/include"
        "--with-freetype-lib=${lib.getLib freetype}/lib"
        "--disable-warnings-as-errors"
      ]
      ++ lib.optional (lib.versionOlder featureVersion "19") "--disable-hotspot-gtest"
      ++ [
        "--with-giflib=system"
        "--with-libjpeg=system"
        "--with-native-debug-symbols=internal"
      ]
      ++ lib.optional (lib.versionAtLeast featureVersion "23") "--with-extra-cxxflags=-I${lib.getDev harfbuzz}/include/harfbuzz"
      ++ lib.optional (lib.versionOlder featureVersion "12") "--disable-freetype-bundling"
      ++ lib.optional (lib.versionAtLeast featureVersion "12") "--with-freetype=system"
      ++ lib.optional (lib.versionAtLeast featureVersion "15") "--with-harfbuzz=system"
      ++ lib.optional (lib.versionAtLeast featureVersion "11") "--disable-javac-server"
      ++ lib.optional headless "--enable-headless-only";
    in
    wrapOpenJdk (
      stdenv.mkDerivation (finalAttrs: {
        pname = "openjdk" + lib.optionalString headless "-headless";
        inherit version;

        src = fetchFromGitHub {
          owner = "openjdk";
          inherit repo tag hash;
        };

        patches =
          lib.optionals (featureVersion == "9") [
            (fetchpatch {
              url = "https://git.savannah.gnu.org/cgit/guix.git/plain/gnu/packages/patches/openjdk-currency-time-bomb.patch";
              hash = "sha256-cA3/YE1/DB5xSU4PlTfjjto5qwF0idAcvDxVTcqQIvA=";
            })
          ]
          ++ lib.optionals (featureVersion == "10") [
            (fetchpatch {
              url = "https://git.savannah.gnu.org/cgit/guix.git/plain/gnu/packages/patches/openjdk-currency-time-bomb2.patch";
              hash = "sha256-5Q0NTn5i4wXITJ4oFOt3t+3btcnwMHJJJF4ezoEwtbo=";
            })
          ];

        nativeBuildInputs = [
          autoPatchelfHook
          pkg-config
          autoconf
          gnumake42
          unzip
          zip
          which
        ];

        buildInputs = [
          cpio
          file
          cups
          freetype
          alsa-lib
          libjpeg
          giflib
          libpng
          lcms2
          libx11
          libice
          libxext
          libxrender
          libxtst
          libxt
          libxi
          libxinerama
          libxcursor
          libxrandr
          fontconfig
          zlib
        ]
        ++ lib.optional (lib.versionAtLeast featureVersion "12") harfbuzz
        ++ lib.optionals (!headless) [
          gtk2
          glib
        ];

        # The OpenJDK makefiles explicitly reject make's -j flag and use
        # JOBS=N instead.
        enableParallelBuilding = false;

        preConfigure = ''
          chmod +x configure
        ''
        + lib.optionalString (lib.versionAtLeast featureVersion "19") ''
          export SOURCE_DATE_EPOCH=315532802
        '';

        configurePhase = ''
          runHook preConfigure
          bash ./configure ${lib.escapeShellArgs bootstrapConfigureFlags} "--with-jobs=${buildJobs}"
          runHook postConfigure
        '';

        buildPhase = ''
          runHook preBuild
          make JOBS="${buildJobs}" images
          runHook postBuild
        '';

        postPatch = ''
          find . -type f \( -name '*.bin' -o -name '*.exe' -o -name '*.jar' \) -delete

          patchShebangs --build configure

          replaceOrAlreadyFixed() {
            local file="$1"
            local old="$2"
            local new="$3"

            if grep -Fq "$old" "$file"; then
              substituteInPlace "$file" --replace-fail "$old" "$new"
            elif grep -Fq "$new" "$file"; then
              :
            else
              echo "could not find expected text in $file" >&2
              exit 1
            fi
          }

          configureScript=
          if [ -f make/autoconf/generated-configure.sh ]; then
            configureScript=make/autoconf/generated-configure.sh
          elif [ -f common/autoconf/generated-configure.sh ]; then
            configureScript=common/autoconf/generated-configure.sh
          fi
          if [ -n "$configureScript" ]; then
            substituteInPlace "$configureScript" --replace-fail "-Werror" ""
          fi

        ''
        + lib.optionalString (lib.versionOlder featureVersion "23") ''
          if [ -f make/jdk/src/classes/build/tools/generatecurrencydata/GenerateCurrencyData.java ]; then
            replaceOrAlreadyFixed make/jdk/src/classes/build/tools/generatecurrencydata/GenerateCurrencyData.java \
              'throw new RuntimeException("time is more than 10 years from present: " + time);' \
              'System.err.println("note: time is more than 10 years from \"present\": " + time);'
          fi
        ''
        + lib.optionalString (lib.versionAtLeast featureVersion "12") ''
          if [ -f src/hotspot/share/utilities/globalDefinitions.hpp ] \
            && grep -Fq 'static inline unsigned int uabs(int n)' src/hotspot/share/utilities/globalDefinitions.hpp
          then
            while IFS= read -r file; do
              substituteInPlace "$file" --replace-fail 'uabs(' 'uabs_hotspot('
            done < <(grep -rl 'uabs(' src/hotspot)
          fi
        ''
        + lib.optionalString (featureVersion == "9") ''
          replaceOrAlreadyFixed hotspot/src/share/vm/memory/virtualspace.cpp \
            'base() > 0' 'base() != NULL'
          replaceOrAlreadyFixed hotspot/src/share/vm/opto/lcm.cpp \
            'Universe::narrow_oop_base() > 0' 'Universe::narrow_oop_base() != NULL'
        ''
        + lib.optionalString (featureVersion == "10") ''
          replaceOrAlreadyFixed src/hotspot/os/linux/os_linux.cpp \
            'if (p < 0)' 'if (p == NULL)'
          replaceOrAlreadyFixed src/hotspot/share/runtime/vm_version.cpp \
            '__DATE__' '""'
          replaceOrAlreadyFixed src/hotspot/share/runtime/vm_version.cpp \
            '__TIME__' '""'
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/lib
          ${selectBuiltJdkImage}
          if [ -z "$image" ]; then
            echo "could not find built JDK image" >&2
            exit 1
          fi
          mv "$image" $out/lib/openjdk

          mkdir -p $out/share
          ln -s $out/lib/openjdk/bin $out/bin
          ln -s $out/lib/openjdk/include $out/include
          if [ -d $out/lib/openjdk/man ]; then
            ln -s $out/lib/openjdk/man $out/share/man
          fi
          if [ -d $out/include/linux ]; then
            ln -s $out/include/linux/*_md.h $out/include/
          fi

          runHook postInstall
        '';

        preFixup = ''
          mkdir -p $out/nix-support
          cat > $out/nix-support/setup-hook <<EOF
          if [ -z "\''${JAVA_HOME-}" ]; then export JAVA_HOME=$out/lib/openjdk; fi
          EOF
        '';

        disallowedReferences = [ bootJdk ];

        passthru = {
          home = "${finalAttrs.finalPackage}/lib/openjdk";
          jdk-bootstrap = bootJdk;
        };

        meta = {
          description = "Open-source Java Development Kit bootstrap stage";
          homepage = "https://openjdk.org/";
          license = lib.licenses.gpl2Only;
          platforms = [
            "x86_64-linux"
            "aarch64-linux"
          ];
        };
      })
    );

  # OpenJDK 8 (Requires OpenJDK 7 / IcedTea 7)
  jdk8_bootstrapped = wrapOpenJdk (openjdk8.override { jdk-bootstrap = icedtea7_bootstrap; });
  jdk8_headless_bootstrapped = wrapOpenJdk (
    openjdk8_headless.override { jdk-bootstrap = icedtea7_bootstrap; }
  );

  # OpenJDK 9 (Requires OpenJDK 8)
  jdk9_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "9";
    version = "9.181";
    repo = "jdk9u";
    tag = "jdk-9+181";
    hash = "sha256-sEVA44UPCQGH58uA3J/ppLAG6n0cXgrzM5ilEPc7DPE=";
    bootJdk = jdk8_bootstrapped;
  };
  jdk9_headless_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "9";
    version = "9.181";
    repo = "jdk9u";
    tag = "jdk-9+181";
    hash = "sha256-sEVA44UPCQGH58uA3J/ppLAG6n0cXgrzM5ilEPc7DPE=";
    bootJdk = jdk8_headless_bootstrapped;
    headless = true;
  };

  # OpenJDK 10 (Requires OpenJDK 9)
  jdk10_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "10";
    version = "10.46";
    repo = "jdk10";
    tag = "jdk-10+46";
    hash = "sha256-fvgO2f3F74b7qFAlLAkEaYxDdHfL/8XjnFn+TlFWh0Q=";
    bootJdk = jdk9_bootstrapped;
  };
  jdk10_headless_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "10";
    version = "10.46";
    repo = "jdk10";
    tag = "jdk-10+46";
    hash = "sha256-fvgO2f3F74b7qFAlLAkEaYxDdHfL/8XjnFn+TlFWh0Q=";
    bootJdk = jdk9_headless_bootstrapped;
    headless = true;
  };

  # OpenJDK 11 (Requires OpenJDK 10)
  # JDK 10's javac can crash while compiling JDK 11's HotSpot JFR/JVMTI
  # generator tools. Build a reduced source JDK 11 first, then use that
  # compiler to build the final feature-complete JDK 11 packages.
  jdk11_stage1_bootstrapped = wrapBootstrapJdk (
    buildOpenJdkImages (
      disableJavacServer (
        patchJdk11BootstrapToolJavacFlags (
          withoutOpenJdkJvmFeatures [
            "jfr"
            "jvmti"
          ] (openjdk11Stable openjdk11_headless { jdk-bootstrap = jdk10_headless_bootstrapped; })
        )
      )
    )
  );

  jdk11_bootstrapped = wrapOpenJdk (
    buildOpenJdkImages (
      disableJavacServer (openjdk11Stable openjdk11 { jdk-bootstrap = jdk11_stage1_bootstrapped; })
    )
  );
  jdk11_headless_bootstrapped = wrapOpenJdk (
    buildOpenJdkImages (
      disableJavacServer (
        openjdk11Stable openjdk11_headless { jdk-bootstrap = jdk11_stage1_bootstrapped; }
      )
    )
  );

  # OpenJDK 12 (Requires OpenJDK 11)
  jdk12_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "12";
    version = "12.0.2";
    repo = "jdk12u";
    tag = "jdk-12.0.2-ga";
    hash = "sha256-c7HKYceKNplC/Bb+GR21gsYI0Svt4AOq/TkgnwhdheY=";
    bootJdk = jdk11_bootstrapped;
  };
  jdk12_headless_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "12";
    version = "12.0.2";
    repo = "jdk12u";
    tag = "jdk-12.0.2-ga";
    hash = "sha256-c7HKYceKNplC/Bb+GR21gsYI0Svt4AOq/TkgnwhdheY=";
    bootJdk = jdk11_headless_bootstrapped;
    headless = true;
  };

  # OpenJDK 13 (Requires OpenJDK 12)
  jdk13_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "13";
    version = "13.0.9";
    repo = "jdk13u";
    tag = "jdk-13.0.9-ga";
    hash = "sha256-KxONV2zv7HpD2p8KfvRpv4EJnxHl4ZWQcKrJ105cV4k=";
    bootJdk = jdk12_bootstrapped;
  };
  jdk13_headless_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "13";
    version = "13.0.9";
    repo = "jdk13u";
    tag = "jdk-13.0.9-ga";
    hash = "sha256-KxONV2zv7HpD2p8KfvRpv4EJnxHl4ZWQcKrJ105cV4k=";
    bootJdk = jdk12_headless_bootstrapped;
    headless = true;
  };

  # OpenJDK 14 (Requires OpenJDK 13)
  jdk14_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "14";
    version = "14.0.2";
    repo = "jdk14u";
    tag = "jdk-14.0.2-ga";
    hash = "sha256-Bjueu3HnS0IqLZn11qsJKaqm4bYmfVCs+MJ53pdeaR4=";
    bootJdk = jdk13_bootstrapped;
  };
  jdk14_headless_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "14";
    version = "14.0.2";
    repo = "jdk14u";
    tag = "jdk-14.0.2-ga";
    hash = "sha256-Bjueu3HnS0IqLZn11qsJKaqm4bYmfVCs+MJ53pdeaR4=";
    bootJdk = jdk13_headless_bootstrapped;
    headless = true;
  };

  # OpenJDK 15 (Requires OpenJDK 14)
  jdk15_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "15";
    version = "15.0.9";
    repo = "jdk15u";
    tag = "jdk-15.0.9-ga";
    hash = "sha256-6lhk6UnC9HHG/rKbWhCGjy6EE9KIey21J4gmtJ0Bfcw=";
    bootJdk = jdk14_bootstrapped;
  };
  jdk15_headless_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "15";
    version = "15.0.9";
    repo = "jdk15u";
    tag = "jdk-15.0.9-ga";
    hash = "sha256-6lhk6UnC9HHG/rKbWhCGjy6EE9KIey21J4gmtJ0Bfcw=";
    bootJdk = jdk14_headless_bootstrapped;
    headless = true;
  };

  # OpenJDK 16 (Requires OpenJDK 15)
  jdk16_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "16";
    version = "16.0.2";
    repo = "jdk16u";
    tag = "jdk-16.0.2-ga";
    hash = "sha256-/8XHNrf9joCCXMCyPncT54JhqlF+KBL7eAf8hUW/BxU=";
    bootJdk = jdk15_bootstrapped;
  };
  jdk16_headless_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "16";
    version = "16.0.2";
    repo = "jdk16u";
    tag = "jdk-16.0.2-ga";
    hash = "sha256-/8XHNrf9joCCXMCyPncT54JhqlF+KBL7eAf8hUW/BxU=";
    bootJdk = jdk15_headless_bootstrapped;
    headless = true;
  };

  # OpenJDK 17 (Requires OpenJDK 16)
  jdk17_bootstrapped = wrapOpenJdk (
    buildOpenJdkImages (disableJavacServer (openjdk17.override { jdk-bootstrap = jdk16_bootstrapped; }))
  );
  jdk17_headless_bootstrapped = wrapOpenJdk (
    buildOpenJdkImages (
      disableJavacServer (openjdk17_headless.override { jdk-bootstrap = jdk16_headless_bootstrapped; })
    )
  );

  # OpenJDK 18 (Requires OpenJDK 17)
  jdk18_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "18";
    version = "18.0.2.1";
    repo = "jdk18u";
    tag = "jdk-18.0.2.1-ga";
    hash = "sha256-L6dsN0kqWcfemM8LBg62qtHQdymwRQoV1ndc8r+0qn8=";
    bootJdk = jdk17_bootstrapped;
  };
  jdk18_headless_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "18";
    version = "18.0.2.1";
    repo = "jdk18u";
    tag = "jdk-18.0.2.1-ga";
    hash = "sha256-L6dsN0kqWcfemM8LBg62qtHQdymwRQoV1ndc8r+0qn8=";
    bootJdk = jdk17_headless_bootstrapped;
    headless = true;
  };

  # OpenJDK 19 (Requires OpenJDK 18)
  jdk19_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "19";
    version = "19.0.2";
    repo = "jdk19u";
    tag = "jdk-19.0.2-ga";
    hash = "sha256-pBEHmBtIgG4Czou4C/zpBBYZEDImvXiLoA5CjOzpeyI=";
    bootJdk = jdk18_bootstrapped;
  };
  jdk19_headless_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "19";
    version = "19.0.2";
    repo = "jdk19u";
    tag = "jdk-19.0.2-ga";
    hash = "sha256-pBEHmBtIgG4Czou4C/zpBBYZEDImvXiLoA5CjOzpeyI=";
    bootJdk = jdk18_headless_bootstrapped;
    headless = true;
  };

  # OpenJDK 20 (Requires OpenJDK 19)
  jdk20_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "20";
    version = "20.0.2";
    repo = "jdk20u";
    tag = "jdk-20.0.2-ga";
    hash = "sha256-CZH2JwR+MrkTlLdcVYuFRB3McdrM0A+1YaSjNpjYwak=";
    bootJdk = jdk19_bootstrapped;
  };
  jdk20_headless_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "20";
    version = "20.0.2";
    repo = "jdk20u";
    tag = "jdk-20.0.2-ga";
    hash = "sha256-CZH2JwR+MrkTlLdcVYuFRB3McdrM0A+1YaSjNpjYwak=";
    bootJdk = jdk19_headless_bootstrapped;
    headless = true;
  };

  # OpenJDK 21 (Requires OpenJDK 20)
  jdk21_bootstrapped = wrapOpenJdk (
    buildOpenJdkImages (disableJavacServer (openjdk21.override { jdk-bootstrap = jdk20_bootstrapped; }))
  );
  jdk21_headless_bootstrapped = wrapOpenJdk (
    buildOpenJdkImages (
      disableJavacServer (openjdk21_headless.override { jdk-bootstrap = jdk20_headless_bootstrapped; })
    )
  );

  # OpenJDK 22 (Requires OpenJDK 21)
  jdk22_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "22";
    version = "22.0.2";
    repo = "jdk22u";
    tag = "jdk-22.0.2-ga";
    hash = "sha256-Zo1LOumkt9zTaPqbDcRL8lVJMqVle0QqzThtIz0JRNo=";
    bootJdk = jdk21_bootstrapped;
  };
  jdk22_headless_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "22";
    version = "22.0.2";
    repo = "jdk22u";
    tag = "jdk-22.0.2-ga";
    hash = "sha256-Zo1LOumkt9zTaPqbDcRL8lVJMqVle0QqzThtIz0JRNo=";
    bootJdk = jdk21_headless_bootstrapped;
    headless = true;
  };

  # OpenJDK 23 (Requires OpenJDK 22)
  jdk23_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "23";
    version = "23.0.2";
    repo = "jdk23u";
    tag = "jdk-23.0.2-ga";
    hash = "sha256-zlL2DV6iOfV3hgq/Ci95gTwVrhcvz5MWsg4/+O2ntE8=";
    bootJdk = jdk22_bootstrapped;
  };
  jdk23_headless_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "23";
    version = "23.0.2";
    repo = "jdk23u";
    tag = "jdk-23.0.2-ga";
    hash = "sha256-zlL2DV6iOfV3hgq/Ci95gTwVrhcvz5MWsg4/+O2ntE8=";
    bootJdk = jdk22_headless_bootstrapped;
    headless = true;
  };

  # OpenJDK 24 (Requires OpenJDK 23)
  jdk24_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "24";
    version = "24.0.2";
    repo = "jdk24u";
    tag = "jdk-24.0.2-ga";
    hash = "sha256-YgkTSh7U/tJxiJIi8fxCkVgcogMQbcN4PgjmlcHcOBE=";
    bootJdk = jdk23_bootstrapped;
  };
  jdk24_headless_bootstrapped = mkOpenJdkBootstrap {
    featureVersion = "24";
    version = "24.0.2";
    repo = "jdk24u";
    tag = "jdk-24.0.2-ga";
    hash = "sha256-YgkTSh7U/tJxiJIi8fxCkVgcogMQbcN4PgjmlcHcOBE=";
    bootJdk = jdk23_headless_bootstrapped;
    headless = true;
  };

  # OpenJDK 25 (Requires OpenJDK 24)
  jdk25_bootstrapped = wrapOpenJdk (
    buildOpenJdkImages (disableJavacServer (openjdk25.override { jdk-bootstrap = jdk24_bootstrapped; }))
  );
  jdk25_headless_bootstrapped = wrapOpenJdk (
    buildOpenJdkImages (
      disableJavacServer (openjdk25_headless.override { jdk-bootstrap = jdk24_headless_bootstrapped; })
    )
  );
in
{
  inherit
    jdk8_bootstrapped
    jdk8_headless_bootstrapped
    jdk9_bootstrapped
    jdk9_headless_bootstrapped
    jdk10_bootstrapped
    jdk10_headless_bootstrapped
    jdk11_bootstrapped
    jdk11_headless_bootstrapped
    jdk17_bootstrapped
    jdk17_headless_bootstrapped
    jdk21_bootstrapped
    jdk21_headless_bootstrapped
    jdk25_bootstrapped
    jdk25_headless_bootstrapped
    ;
}
