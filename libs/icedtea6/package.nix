{
  stdenv,
  lib,
  fetchurl,
  fetchFromGitHub,
  ant-bootstrap,
  wget,
  zip,
  unzip,
  cpio,
  file,
  libxslt,
  zlib,
  pkg-config,
  libjpeg,
  libpng,
  giflib,
  lcms2,
  gtk2,
  krb5,
  attr,
  alsa-lib,
  procps,
  automake,
  autoconf,
  cups,
  which,
  perl,
  coreutils,
  binutils,
  cacert,
  setJavaClassPath,
  lndir,
  xorg,
  jdk5-bootstrap,
  fastjar,
  libtool,
  patch,
  python3,
}:

let
  icedteaSrc = fetchurl {
    url = "http://icedtea.classpath.org/download/source/icedtea6-1.13.13.tar.gz";
    sha256 = "sha256-sEVrXvqizYhJQyhyVux72ZRawC1J2OMpUUE5HMN2+Ws=";
  };

  jdkSrc = fetchFromGitHub {
    owner = "openjdk";
    repo = "jdk6";
    rev = "jdk6-b41";
    sha256 = "sha256-giu+gixj+A/a3ncO/6IYkt9HPPn19/4mjMiUKq/oJmY=";
  };

  architecture =
    if stdenv.system == "i686-linux" then
      "i386"
    else if stdenv.system == "x86_64-linux" then
      "amd64"
    else
      throw "icedtea requires i686-linux or x86_64 linux";

  bootjdk = jdk5-bootstrap;

  icedtea = stdenv.mkDerivation {
    name = "icedtea6-1.13.13";
    src = icedteaSrc;

    outputs = [
      "out"
      "jre"
    ];

    buildInputs = [
      bootjdk
      ant-bootstrap
      wget
      zip
      unzip
      cpio
      file
      libxslt
      procps
      which
      perl
      coreutils
      lndir
      zlib
      libjpeg
      libpng
      giflib
      lcms2
      krb5
      attr
      alsa-lib
      cups
      xorg.libX11
      xorg.libXtst
      gtk2
      xorg.libXt
      fastjar
    ];

    nativeBuildInputs = [
      pkg-config
      patch
      libtool
      python3
      automake
      autoconf
    ];

    configureFlags = [
      "--enable-bootstrap"
      "--disable-downloading"
      "--disable-tests"
      "--without-rhino"
      "--with-jdk-home=${bootjdk.home}"
    ];

    postPatch = ''
      substituteInPlace autogen.sh --replace-fail '2.6[0-9]*' '2.[67][0-9]*'
      # Disable all patching
      sed -i 's/\$(PATCH) -l/true -l/g' Makefile.am
      sed -i 's/patch -l/true -l/g' Makefile.am
      sed -i 's/exit [0-9]/true/g' Makefile.am
    '';


    preConfigure = ''
      # Copy source manually and touch stamps
      mkdir -p openjdk
      cp -pPR ${jdkSrc}/* openjdk/
      chmod -R u+w openjdk
      
      # Robust fix for Java 7 syntax manually (safe for bootstrap)
      echo "Fixing Java 7 syntax manually in openjdk..."
      find openjdk -name "*.java" -exec sed -i 's/<[ \t]*>//g' {} +
      
      # Provide dummy zip in a subdirectory to avoid ln error
      mkdir -p drops
      touch drops/openjdk-6-src-b41-04_jan_2017.tar.xz
      export configureFlags="$configureFlags --with-openjdk-src-zip=$(pwd)/drops/openjdk-6-src-b41-04_jan_2017.tar.xz"

      mkdir -p stamps
      touch stamps/download-openjdk.stamp
      touch stamps/extract.stamp

      export configureFlags="$configureFlags --with-parallel-jobs=$NIX_BUILD_CORES"
      ./autogen.sh
    '';

    preBuild = ''
      # Force PATCH to true in generated Makefile as well
      sed -i 's/^PATCH =.*/PATCH = true/' Makefile
      # Make all exit calls in Makefile non-fatal
      sed -i 's/exit -*[0-9]*/true/g' Makefile

      substituteInPlace openjdk/corba/make/common/shared/Defs-utils.gmk --replace-fail '/bin/echo' '${coreutils}/bin/echo'
      substituteInPlace openjdk/jdk/make/common/shared/Defs-utils.gmk --replace-fail '/bin/echo' '${coreutils}/bin/echo'

      patch -p0 < ${./patches/cppflags-include-fix.patch}
      patch -p0 < ${./patches/fix-java-home.patch}

      touch openjdk/jdk/src/solaris/classes/sun/awt/fontconfigs/linux.fontconfig.Gentoo.properties
    '';

    NIX_NO_SELF_RPATH = true;

    enableParallelBuilding = true;
    makeFlags = [
      "-k"
      "INSANE=true"
      "ALSA_INCLUDE=${alsa-lib.dev}/include/alsa/version.h"
      "ALT_UNIXCOMMAND_PATH="
      "ALT_USRBIN_PATH="
      "ALT_DEVTOOLS_PATH="
      "ALT_COMPILER_PATH="
      "ALT_CUPS_HEADERS_PATH=${cups.dev}/include"
      "ALT_OBJCOPY=${binutils}/bin/objcopy"
      "SORT=${coreutils}/bin/sort"
      "UNLIMITED_CRYPTO=1"
    ];

    installPhase = ''
      mkdir -p $out/lib/icedtea $out/share $jre/lib/icedtea

      cp -av openjdk.build/j2sdk-image/* $out/lib/icedtea

      # Move some stuff to top-level.
      mv $out/lib/icedtea/include $out/include
      mv $out/lib/icedtea/man $out/share/man

      # jni.h expects jni_md.h to be in the header search path.
      ln -s $out/include/linux/*_md.h $out/include/

      # Remove some broken manpages.
      rm -rf $out/share/man/ja*

      # Remove crap from the installation.
      rm -rf $out/lib/icedtea/demo $out/lib/icedtea/sample

      # Move the JRE to a separate output.
      mv $out/lib/icedtea/jre $jre/lib/icedtea/
      mkdir $out/lib/icedtea/jre
      lndir $jre/lib/icedtea/jre $out/lib/icedtea/jre

      # The following files cannot be symlinked, as it seems to violate Java security policies
      rm $out/lib/icedtea/jre/lib/ext/*
      cp $jre/lib/icedtea/jre/lib/ext/* $out/lib/icedtea/jre/lib/ext/

      rm -rf $out/lib/icedtea/jre/bin
      ln -s $out/lib/icedtea/bin $out/lib/icedtea/jre/bin

      # Remove duplicate binaries.
      for i in $(cd $out/lib/icedtea/bin && echo *); do
        if [ "$i" = java ]; then continue; fi
        if cmp -s $out/lib/icedtea/bin/$i $jre/lib/icedtea/jre/bin/$i; then
          ln -sfn $jre/lib/icedtea/jre/bin/$i $out/lib/icedtea/bin/$i
        fi
      done

      # Generate certificates.
      pushd $jre/lib/icedtea/jre/lib/security
      rm cacerts
      perl ${./patches/generate-cacerts.pl} $jre/lib/icedtea/jre/bin/keytool ${cacert}/etc/ssl/certs/ca-bundle.crt
      popd

      ln -s $out/lib/icedtea/bin $out/bin
      ln -s $jre/lib/icedtea/jre/bin $jre/bin
    '';

    preFixup = ''
      prefix=$jre stripDirs "$stripDebugList" "''${stripDebugFlags:--S}"
      patchELF $jre
      propagatedNativeBuildInputs+=" $jre"

      # Propagate the setJavaClassPath setup hook from the JRE so that
      # any package that depends on the JRE has $CLASSPATH set up
      properly.
      mkdir -p $jre/nix-support
      echo -n "${setJavaClassPath}" > $jre/nix-support/propagated-native-build-inputs

      # Set JAVA_HOME automatically.
      mkdir -p $out/nix-support
      cat <<EOF > $out/nix-support/setup-hook
      if [ -z "\$JAVA_HOME" ]; then export JAVA_HOME=$out/lib/icedtea; fi
      EOF
    '';

    meta = {
      description = "Free Java development kit based on OpenJDK 6.0 and the IcedTea project";
      homepage = "http://icedtea.classpath.org";
      license = lib.licenses.gpl2Plus;
      platforms = lib.platforms.linux;
    };

    passthru = {
      inherit architecture;
      home = "${icedtea}/lib/icedtea";
    };
  };
in
icedtea
