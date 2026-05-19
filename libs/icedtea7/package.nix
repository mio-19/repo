{
  stdenv,
  lib,
  fetchFromGitHub,
  fetchurl,
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
  autoconf269,
  libtool,
  cups,
  which,
  perl,
  coreutils,
  binutils,
  cacert,
  setJavaClassPath,
  lndir,
  libx11,
  libxtst,
  libxt,
  jdk5-bootstrap,
  patch,
  python3,
}:

let

  icedteaSrc = fetchFromGitHub {
    owner = "icedtea-git";
    repo = "icedtea";
    rev = "icedtea-2.6.28";
    hash = "sha256-2XyAQmiK9YKpvgPKl11ratjSgNEE453jHyiWox0oyAk=";
  };

  dropBase = "https://icedtea.classpath.org/download/drops/icedtea7/2.6.28";
  fetchDrop =
    name: hash:
    fetchurl {
      url = "${dropBase}/${name}.tar.bz2";
      inherit hash;
    };

  openjdkSrcZip = fetchDrop "openjdk" "sha256-eOXon8UQKAQB4ifZgKvjDUnqUIw+7FNwNUgf0ho7LDI=";
  corbaSrcZip = fetchDrop "corba" "sha256-sAIkBiG+QEeD7QEX/gUlUrTvhq2t5PLIVhzO5g7LqEU=";
  jaxpSrcZip = fetchDrop "jaxp" "sha256-/ZPmWkaSWTwhAJY74sddaXoyulHuLALH59zMUk37F4g=";
  jaxwsSrcZip = fetchDrop "jaxws" "sha256-I7LGIXUmCPA/i2F1PhmyEkbdWFBki836SfLGuM2TCi8=";
  jdkSrcZip = fetchDrop "jdk" "sha256-CBImmx+KOITSwmWdlE4g/PsFTZFqVxLkBdelT6srUWc=";
  langtoolsSrcZip = fetchDrop "langtools" "sha256-JHmdXr6/seMW+UNNsdtaNgrHyG5Xg85YaTU2+Xigqkc=";
  hotspotSrcZip = fetchDrop "hotspot" "sha256-tol81d1wryAebKEHsnWSF/ksogdkPFEo3MqeCjOzTPw=";

  /**
    The JRE libraries are in directories that depend on the CPU.
  */
  architecture =
    if stdenv.system == "i686-linux" then
      "i386"
    else if stdenv.system == "x86_64-linux" then
      "amd64"
    else
      throw "icedtea requires i686-linux or x86_64 linux";

  bootjdk = jdk5-bootstrap;

  icedtea = stdenv.mkDerivation {

    name = icedteaSrc.rev;
    src = icedteaSrc;

    outputs = [
      "out"
      "jre"
    ];

    # TODO: Probably some more dependencies should be on this list but are being
    # propagated instead
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
      automake
      autoconf269
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
      libx11
      libxtst
      gtk2
      libxt
    ];

    nativeBuildInputs = [
      pkg-config
      automake
      autoconf269
      libtool
      patch
      python3
    ];

    configureFlags = [
      "--enable-bootstrap"
      "--disable-downloading"

      "--disable-system-sctp"
      "--disable-system-pcsc"
      # "--enable-system-lcms"
      # "--enable-nss"

      "--disable-tests" # TODO run in check phase instead

      "--without-rhino"
      "--with-pax=paxctl"
      "--with-jdk-home=${bootjdk.home}"
      "--with-openjdk-src-zip=${openjdkSrcZip}"
      "--with-corba-src-zip=${corbaSrcZip}"
      "--with-jaxp-src-zip=${jaxpSrcZip}"
      "--with-jaxws-src-zip=${jaxwsSrcZip}"
      "--with-jdk-src-zip=${jdkSrcZip}"
      "--with-langtools-src-zip=${langtoolsSrcZip}"
      "--with-hotspot-src-zip=${hotspotSrcZip}"

    ];

    ## FIXME also need to patch some source files
    postPatch = ''
      substituteInPlace Makefile.am \
        --replace-fail 'LANG="C" \' 'LANG="C.UTF-8" \
        LC_ALL="C.UTF-8" \'
      substituteInPlace acinclude.m4 --replace-fail 'attr/xattr.h' 'sys/xattr.h'
    '';

    preConfigure = ''
      export configureFlags="$configureFlags --with-parallel-jobs=$NIX_BUILD_CORES"
      ./autogen.sh
    '';

    preBuild = ''
      make stamps/patch-boot.stamp

      replaceOrAlreadyFixed() {
        local file="$1"
        local from="$2"
        local to="$3"

        if grep -Fq "$from" "$file"; then
          substituteInPlace "$file" --replace-fail "$from" "$to"
        else
          grep -Fq "$to" "$file"
        fi
      }

      removeIfPresent() {
        local file="$1"
        local from="$2"

        if grep -Fq "$from" "$file"; then
          substituteInPlace "$file" --replace-fail "$from" ""
        fi
      }

      replaceBinEcho() {
        local file="$1"

        if ! grep -Fq '${coreutils}/bin/echo' "$file"; then
          substituteInPlace "$file" --replace-fail '/bin/echo' '${coreutils}/bin/echo'
        fi
      }

      for openjdkTree in openjdk openjdk-boot; do
        mv "$openjdkTree/hotspot/agent" "$openjdkTree/hotspot/agent.disabled"
        replaceBinEcho "$openjdkTree/corba/make/common/shared/Defs-utils.gmk"
        replaceBinEcho "$openjdkTree/jdk/make/common/shared/Defs-utils.gmk"
        replaceOrAlreadyFixed "$openjdkTree/hotspot/src/share/vm/opto/lcm.cpp" \
          'Universe::narrow_oop_base() > 0' 'Universe::narrow_oop_base() != NULL'
        replaceOrAlreadyFixed "$openjdkTree/hotspot/src/share/vm/runtime/virtualspace.cpp" \
          'base() > 0' 'base() != NULL'
        replaceOrAlreadyFixed "$openjdkTree/hotspot/make/linux/makefiles/saproc.make" \
          '$(SA_DEBUG_CFLAGS)' '$(SA_DEBUG_CFLAGS) -std=gnu89'
        replaceOrAlreadyFixed "$openjdkTree/hotspot/make/linux/makefiles/sa.make" \
          '$(COMPILE.RMIC)  -classpath $(SA_CLASSDIR)' '$(COMPILE.RMIC) -J-Dfile.encoding=UTF-8 -J-Dsun.jnu.encoding=UTF-8 -classpath $(SA_CLASSDIR)'
        replaceOrAlreadyFixed "$openjdkTree/hotspot/make/linux/makefiles/defs.make" \
          'EXPORT_LIST += $(ADD_SA_BINARIES/$(HS_ARCH))' '# EXPORT_LIST += $(ADD_SA_BINARIES/$(HS_ARCH))'
        replaceOrAlreadyFixed "$openjdkTree/jdk/src/share/native/common/jni_util.h" \
          'void initializeEncoding();' 'void initializeEncoding(JNIEnv *env);'
        replaceOrAlreadyFixed "$openjdkTree/jdk/src/share/bin/java.c" \
          'static void GrowKnownVMs();' 'static void GrowKnownVMs(int minimum);'
        removeIfPresent "$openjdkTree/jdk/src/solaris/native/java/net/PlainDatagramSocketImpl.c" '#include <sys/sysctl.h>'
        removeIfPresent "$openjdkTree/jdk/src/solaris/native/java/net/PlainSocketImpl.c" '#include <sys/sysctl.h>'
        replaceOrAlreadyFixed "$openjdkTree/jdk/src/solaris/native/sun/nio/fs/LinuxNativeDispatcher.c" \
          '#include <attr/xattr.h>' '#include <sys/xattr.h>'
        replaceOrAlreadyFixed "$openjdkTree/jdk/src/share/classes/sun/security/util/Optional.java" \
          'return Optional.ofNullable(mapper.apply(value));' 'return Optional.<U>ofNullable(mapper.apply(value));'
        replaceOrAlreadyFixed "$openjdkTree/jdk/src/share/native/sun/awt/medialib/awt_ImagingLib.h" \
          'mlib_status (*fptr)();' 'mlib_status (*fptr)(void *, ...);'
        removeIfPresent "$openjdkTree/jdk/src/solaris/native/sun/awt/awt_GraphicsEnv.h" 'extern int XShmQueryExtension();'
        replaceOrAlreadyFixed "$openjdkTree/jdk/src/solaris/native/sun/awt/list.h" '#if NeedFunctionPrototypes' '#if 1'
        replaceOrAlreadyFixed "$openjdkTree/jdk/src/solaris/native/sun/awt/list.c" '#if NeedFunctionPrototypes' '#if 1'
        replaceOrAlreadyFixed "$openjdkTree/jdk/src/solaris/native/sun/awt/gtk2_interface.c" \
          'gint intval = NULL;' 'gint intval = 0;'
        replaceOrAlreadyFixed "$openjdkTree/jdk/src/share/native/com/sun/java/util/jar/pack/utils.cpp" \
          'fprintf(stdout, 1+message);' 'fprintf(stdout, "%s", 1+message);'

        patch -d "$openjdkTree" -p1 < ${./patches/cppflags-include-fix.patch}
        patch -d "$openjdkTree" -p1 < ${./patches/fix-java-home.patch}

        touch "$openjdkTree/jdk/src/solaris/classes/sun/awt/fontconfigs/linux.fontconfig.Gentoo.properties"
      done
    '';

    patches = [
      ./patches/0001-make-jpeg-6b-optional.patch
    ];

    NIX_NO_SELF_RPATH = true;
    EXTRA_CFLAGS = "-fcommon -Wno-error=incompatible-pointer-types";

    enableParallelBuilding = true;
    makeFlags = [
      "ALSA_INCLUDE=${lib.getDev alsa-lib}/include/alsa/version.h"
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

      # Mirror some stuff at top-level, while keeping passthru.home a complete
      # JDK home for consumers that look for include/ under it.
      ln -s $out/lib/icedtea/include $out/include
      mv $out/lib/icedtea/man $out/share/man

      # jni.h expects jni_md.h to be in the header search path.
      ln -s $out/lib/icedtea/include/linux/*_md.h $out/lib/icedtea/include/

      # Remove some broken manpages.
      rm -rf $out/share/man/ja*

      # Remove crap from the installation.
      rm -rf $out/lib/icedtea/demo $out/lib/icedtea/sample

      # Keep an independent JRE in both outputs. Symlinking the JDK output
      # into the JRE output creates an output reference cycle with current Nix.
      cp -a $out/lib/icedtea/jre $jre/lib/icedtea/

      # Generate certificates.
      pushd $jre/lib/icedtea/jre/lib/security
      rm cacerts
      perl ${./patches/generate-cacerts.pl} $jre/lib/icedtea/jre/bin/keytool ${cacert}/etc/ssl/certs/ca-bundle.crt
      popd
      cp $jre/lib/icedtea/jre/lib/security/cacerts $out/lib/icedtea/jre/lib/security/cacerts

      ln -s $out/lib/icedtea/bin $out/bin
      ln -s $jre/lib/icedtea/jre/bin $jre/bin
    '';

    # Extra setup for the split JRE output; generic fixup already handles all
    # outputs in current stdenv.
    preFixup = ''
      patchELF $jre

      # Propagate the setJavaClassPath setup hook from the JRE so that
      # any package that depends on the JRE has $CLASSPATH set up
      # properly.
      mkdir -p $jre/nix-support
      echo -n "${setJavaClassPath}" > $jre/nix-support/propagated-native-build-inputs

      # Set JAVA_HOME automatically.
      mkdir -p $out/nix-support
      cat <<EOF > $out/nix-support/setup-hook
      if [ -z "\$JAVA_HOME" ]; then export JAVA_HOME=$out/lib/icedtea; fi
      EOF
    '';

    meta = {
      description = "Free Java development kit based on OpenJDK 7.0 and the IcedTea project";
      longDescription = ''
        Free Java environment based on OpenJDK 7.0 and the IcedTea project.
        - Full Java runtime environment
        - Needed for executing Java Webstart programs and the free Java web browser plugin.
      '';
      homepage = "http://icedtea.classpath.org";
      maintainers = with lib.maintainers; [ bendlas ];
      platforms = lib.platforms.linux;
    };

    passthru = {
      inherit architecture;
      home = "${icedtea}/lib/icedtea";
    };
  };
in
icedtea
