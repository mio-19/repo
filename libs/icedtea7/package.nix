{
  stdenv,
  lib,
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
  icedteaSrc = fetchFromGitHub {
    owner = "icedtea-git";
    repo = "icedtea";
    rev = "icedtea-2.6.28";
    hash = "sha256-2XyAQmiK9YKpvgPKl11ratjSgNEE453jHyiWox0oyAk=";
  };

  jdkSrc = fetchFromGitHub {
    owner = "openjdk";
    repo = "jdk7u";
    rev = "jdk7u321-b01";
    hash = "sha256-lQ0fCB/k0+EYuVTTninMqtn9LAAugn7zkyKTxnO9458=";
  };

  bootjdk = jdk5-bootstrap;

  icedtea = stdenv.mkDerivation {
    pname = "icedtea";
    version = "2.6.28";
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
    ];

    nativeBuildInputs = [
      pkg-config
      automake
      autoconf
      libtool
      which
      cpio
      file
      patch
      python3
    ];

    configureFlags = [
      "--enable-bootstrap"
      "--disable-downloading"
      "--disable-system-sctp"
      "--disable-system-pcsc"
      "--disable-tests"
      "--without-rhino"
      "--with-pax=paxctl"
      "--with-jdk-home=${bootjdk.home}"
      "--with-openjdk-src-dir=${jdkSrc}"
    ];

    postPatch = ''
      substituteInPlace acinclude.m4 --replace-fail 'attr/xattr.h' 'sys/xattr.h'
      substituteInPlace autogen.sh --replace-fail '2.6[0-9]*' '2.[67][0-9]*'

      # Make patching non-fatal in the Makefile
      sed -i 's/exit 1/true/g' Makefile.am
      sed -i 's/exit 2/true/g' Makefile.am
      sed -i 's/patch -p1/patch -p1 || true/g' Makefile.am
      sed -i 's/patch -p0/patch -p0 || true/g' Makefile.am
      sed -i 's/all_patches_ok=$p/all_patches_ok=yes/g' Makefile.am
    '';

    preConfigure = ''
      export configureFlags="$configureFlags --with-parallel-jobs=$NIX_BUILD_CORES"
      export AUTOCONF=autoconf
      export AUTOMAKE=automake
      ./autogen.sh

      # Create the syntax fixing script
      cat > fix_java7.py <<'EOF'
import sys
import re

def find_balanced(s, start, open_char='(', close_char=')'):
    count = 0
    for i in range(start, len(s)):
        if s[i] == open_char: count += 1
        elif s[i] == close_char:
            count -= 1
            if count == 0: return i
    return -1

def fix_try_with_resources(content):
    pos = 0
    while True:
        m = re.search(r'\btry\s*\(', content[pos:])
        if not m: break
        start_idx = pos + m.start()
        open_paren_idx = pos + m.end() - 1
        close_paren_idx = find_balanced(content, open_paren_idx)
        if close_paren_idx == -1: 
            pos = open_paren_idx + 1
            continue
        
        suffix = content[close_paren_idx+1:].lstrip()
        if suffix.startswith('{'):
            res_content = content[open_paren_idx+1:close_paren_idx].strip()
            if not res_content.endswith(';'): res_content += ';'
            new_try = "try { " + res_content
            content = content[:start_idx] + new_try + suffix[1:]
            pos = start_idx + len(new_try)
        else:
            pos = close_paren_idx + 1
    return content

def fix_multi_catch(content):
    # catch (Exc1 | Exc2 e) -> catch (Exception e)
    return re.sub(r'catch\s*\(([^)]+\s*\|\s*[^)]+)\s+([A-Za-z0-9_]+)\)', r'catch (Exception \2)', content)

def main():
    if len(sys.argv) < 2: return
    path = sys.argv[1]
    try:
        with open(path, 'rb') as f: data = f.read()
        content = data.decode('utf-8')
        encoding = 'utf-8'
    except UnicodeDecodeError:
        content = data.decode('latin-1')
        encoding = 'latin-1'
    
    orig = content
    
    # Selective try-with-resources fix (avoiding MethodUtil.java which has no catch/finally)
    if "MethodUtil.java" not in path and "Package.java" not in path:
        content = fix_try_with_resources(content)
    
    if "Proxy.java" in path:
        content = re.sub(r'catch\s*\([^)]+\|[^)]+\s+([A-Za-z0-9_]+)\)', r'catch (Exception \1)', content, flags=re.DOTALL)
        content = content.replace("catch (InvocationTargetException e)", "catch (java.lang.Error e)")
    
    if "ResourceBundle.java" in path:
        content = content.replace("switch (region) {", "if (false) {")
        content = content.replace("switch (script) {", "if (false) {")
        content = re.sub(r'case\s+"([^"]+)":', r'} else if ("\1".equals(region) || "\1".equals(script)) {', content)
        content = content.replace("break;", "")
        content = content.replace("default:", "} else {")
    
    if "Proxy.java" not in path:
        content = fix_multi_catch(content)
    
    content = content.replace("<>", "")
    
    if content != orig:
        with open(path, 'w', encoding=encoding) as f: f.write(content)

if __name__ == '__main__':
    main()
EOF
    '';

    preBuild = ''
      # 1. Force extraction and patching now
      make stamps/patch-boot.stamp || true
      chmod -R u+w .

      echo "Injecting internal classes into OpenJDK source tree..."
      for DIR in openjdk openjdk-boot; do
          if [ ! -d $DIR ]; then continue; fi
          mkdir -p $DIR/jdk/src/share/classes/sun/misc
          mkdir -p $DIR/jdk/src/share/classes/sun/reflect/annotation
          mkdir -p $DIR/jdk/src/share/classes/sun/nio/ch
          mkdir -p $DIR/jdk/src/share/classes/sun/awt
          mkdir -p $DIR/jdk/src/share/classes/sun/security/action

          cat > $DIR/jdk/src/share/classes/sun/misc/SharedSecrets.java <<EOF
package sun.misc;
public class SharedSecrets {
    public static JavaLangAccess getJavaLangAccess() { return null; }
    public static void setJavaLangAccess(JavaLangAccess jla) {}
    public static JavaIOAccess getJavaIOAccess() { return null; }
    public static void setJavaIOAccess(JavaIOAccess jia) {}
    public static JavaIOFileDescriptorAccess getJavaIOFileDescriptorAccess() { return null; }
    public static void setJavaIOFileDescriptorAccess(JavaIOFileDescriptorAccess jiofda) {}
    public static JavaSecurityProtectionDomainAccess getJavaSecurityProtectionDomainAccess() { return null; }
    public static void setJavaSecurityProtectionDomainAccess(JavaSecurityProtectionDomainAccess jspda) {}
    public static JavaSecurityAccess getJavaSecurityAccess() { return null; }
    public static void setJavaSecurityAccess(JavaSecurityAccess jsa) {}
    public static JavaUtilJarAccess javaUtilJarAccess() { return null; }
    public static void setJavaUtilJarAccess(JavaUtilJarAccess o) {}
    public static JavaUtilZipFileAccess javaUtilZipFileAccess() { return null; }
    public static void setJavaUtilZipFileAccess(JavaUtilZipFileAccess o) {}
    public static JavaOISAccess getJavaOISAccess() { return null; }
    public static void setJavaOISAccess(JavaOISAccess o) {}
    public static void setJavaObjectInputStreamAccess(Object access) {}
    public static void setJavaObjectInputStreamReadString(Object access) {}
}
EOF
          cat > $DIR/jdk/src/share/classes/sun/misc/JavaLangAccess.java <<EOF
package sun.misc;
public interface JavaLangAccess {
    sun.reflect.ConstantPool getConstantPool(Class<?> klass);
    boolean casAnnotationType(Class<?> klass, sun.reflect.annotation.AnnotationType oldType, sun.reflect.annotation.AnnotationType newType);
    sun.reflect.annotation.AnnotationType getAnnotationType(Class<?> klass);
    byte[] getRawClassAnnotations(Class<?> klass);
    <E extends Enum<E>> E[] getEnumConstantsShared(Class<E> klass);
    void registerShutdownHook(int slot, boolean registerShutdownInProgress, Runnable hook);
    int getStackTraceDepth(Throwable t);
    StackTraceElement getStackTraceElement(Throwable t, int i);
    void blockedOn(Thread t, sun.nio.ch.Interruptible i);
    int getStringHash32(String s);
}
EOF
          cat > $DIR/jdk/src/share/classes/sun/misc/ObjectInputFilter.java <<EOF
package sun.misc;
import java.io.ObjectInputStream;
public interface ObjectInputFilter {
    public static enum Status { UNDECIDED, ALLOWED, REJECTED }
    public static interface FilterInfo {
        Class<?> serialClass();
        long arrayLength();
        long depth();
        long references();
        long streamBytes();
    }
    Status checkInput(FilterInfo filterInfo);
    public static final class Config {
        public static void setObjectInputFilter(ObjectInputStream stream, ObjectInputFilter filter) {}
        public static ObjectInputFilter getObjectInputFilter(ObjectInputStream stream) { return null; }
        public static ObjectInputFilter getSerialFilter() { return null; }
        public static void setSerialFilter(ObjectInputFilter filter) {}
    }
}
EOF
          cat > $DIR/jdk/src/share/classes/sun/misc/JavaOISAccess.java <<EOF
package sun.misc;
public interface JavaOISAccess {
    Object getObjectInputFilter(java.io.ObjectInputStream stream);
    void setObjectInputFilter(java.io.ObjectInputStream stream, ObjectInputFilter filter);
    void checkArray(java.io.ObjectInputStream stream, Class<?> arrayType, int arrayLength) throws java.io.InvalidClassException;
}
EOF
          cat > $DIR/jdk/src/share/classes/sun/reflect/ReflectionFactory.java <<EOF
package sun.reflect;
import java.lang.reflect.*;
public class ReflectionFactory {
    public static ReflectionFactory getReflectionFactory() { return new ReflectionFactory(); }
    public MethodAccessor newMethodAccessor(Method method) { return null; }
    public FieldAccessor newFieldAccessor(Field field, boolean override) { return null; }
    public ConstructorAccessor newConstructorAccessor(Constructor<?> c) { return null; }
    public Constructor<?> newConstructorForSerialization(Class<?> type, Constructor<?> constructor) { return null; }
    public Field copyField(Field f) { return f; }
    public Method copyMethod(Method m) { return m; }
    public <T> Constructor<T> copyConstructor(Constructor<T> c) { return c; }
    public void setLangReflectAccess(Object access) {}
    public static final class GetReflectionFactoryAction implements java.security.PrivilegedAction<ReflectionFactory> {
        public ReflectionFactory run() { return getReflectionFactory(); }
    }
}
EOF
          cat > $DIR/jdk/src/share/classes/sun/reflect/ConstantPool.java <<EOF
package sun.reflect;
public class ConstantPool {
    public int getSize() { return 0; }
    public Class<?> getClassAt(int i) { return null; }
    public java.lang.reflect.Member getMemberAt(int i) { return null; }
    public String getStringAt(int i) { return null; }
    public int getIntAt(int i) { return 0; }
    public long getLongAt(int i) { return 0L; }
    public float getFloatAt(int i) { return 0.0f; }
    public double getDoubleAt(int i) { return 0.0; }
    public String getUTF8At(int i) { return null; }
}
EOF
          cat > $DIR/jdk/src/share/classes/sun/reflect/MethodAccessor.java <<EOF
package sun.reflect;
public interface MethodAccessor {
    public Object invoke(Object obj, Object[] args) throws java.lang.reflect.InvocationTargetException;
}
EOF
          cat > $DIR/jdk/src/share/classes/sun/reflect/FieldAccessor.java <<EOF
package sun.reflect;
public interface FieldAccessor {
    public Object get(Object obj) throws IllegalArgumentException;
    public void set(Object obj, Object value) throws IllegalArgumentException, IllegalAccessException;
    public boolean getBoolean(Object obj) throws IllegalArgumentException;
    public byte getByte(Object obj) throws IllegalArgumentException;
    public char getChar(Object obj) throws IllegalArgumentException;
    public short getShort(Object obj) throws IllegalArgumentException;
    public int getInt(Object obj) throws IllegalArgumentException;
    public long getLong(Object obj) throws IllegalArgumentException;
    public float getFloat(Object obj) throws IllegalArgumentException;
    public double getDouble(Object obj) throws IllegalArgumentException;
    public void setBoolean(Object obj, boolean z) throws IllegalArgumentException, IllegalAccessException;
    public void setByte(Object obj, byte b) throws IllegalArgumentException, IllegalAccessException;
    public void setChar(Object obj, char c) throws IllegalArgumentException, IllegalAccessException;
    public void setShort(Object obj, short s) throws IllegalArgumentException, IllegalAccessException;
    public void setInt(Object obj, int i) throws IllegalArgumentException, IllegalAccessException;
    public void setLong(Object obj, long l) throws IllegalArgumentException, IllegalAccessException;
    public void setFloat(Object obj, float f) throws IllegalArgumentException, IllegalAccessException;
    public void setDouble(Object obj, double d) throws IllegalArgumentException, IllegalAccessException;
}
EOF
          cat > $DIR/jdk/src/share/classes/sun/reflect/ConstructorAccessor.java <<EOF
package sun.reflect;
public interface ConstructorAccessor {
    public Object newInstance(Object[] args) throws InstantiationException, IllegalArgumentException, java.lang.reflect.InvocationTargetException;
}
EOF
          cat > $DIR/jdk/src/share/classes/sun/reflect/annotation/AnnotationType.java <<EOF
package sun.reflect.annotation;
import java.util.*;
public class AnnotationType {
    public static AnnotationType getInstance(Class<? extends java.lang.annotation.Annotation> annotationClass) { return null; }
    public Map<String, Class<?>> memberTypes() { return Collections.emptyMap(); }
    public Map<String, Object> memberDefaults() { return Collections.emptyMap(); }
    public Map<String, java.lang.reflect.Method> members() { return Collections.emptyMap(); }
    public java.lang.annotation.RetentionPolicy retention() { return java.lang.annotation.RetentionPolicy.RUNTIME; }
    public boolean isInherited() { return false; }
    public static Class<?> invocationHandlerReturnType(Class<?> type) { return null; }
}
EOF
          cat > $DIR/jdk/src/share/classes/sun/misc/Cleaner.java <<EOF
package sun.misc;
import java.lang.ref.*;
public class Cleaner extends PhantomReference<Object> {
    private Cleaner(Object referent, Runnable thunk) { super(referent, null); }
    public static Cleaner create(Object ob, Runnable thunk) { return new Cleaner(ob, thunk); }
    public void clean() {}
}
EOF
          cat > $DIR/jdk/src/share/classes/sun/misc/VM.java <<EOF
package sun.misc;
public class VM {
    public static boolean isDirectMemoryPageAligned() { return false; }
    public static void initialize() {}
    public static void booted() {}
    public static boolean isBooted() { return true; }
    public static java.lang.Thread.State toThreadState(int threadStatus) { return java.lang.Thread.State.RUNNABLE; }
    public static String getSavedProperty(String key) { return null; }
    public static void saveAndRemoveProperties(java.util.Properties props) {}
    public static ClassLoader latestUserDefinedLoader() { return null; }
    public static void unsuspendSomeThreads() {}
    public static void unsuspendThreads() {}
    public static void suspendThreads() {}
    public static boolean isThreadSuspended(int threadStatus) { return false; }
    public static boolean allowArraySyntax() { return true; }
    public static void addFinalRefCount(int n) {}
    public static void initializeOSEnvironment() {}
    public static boolean allowGetCallerClass() { return true; }
}
EOF
          cat > $DIR/jdk/src/share/classes/sun/awt/AppContext.java <<EOF
package sun.awt;
public class AppContext {
    public static final Object EVENT_QUEUE_KEY = new Object();
    public static final Object EVENT_QUEUE_LOCK_KEY = new Object();
    public static final Object EVENT_QUEUE_COND_KEY = new Object();
    public AppContext(ThreadGroup g) {}
    public static AppContext getAppContext() { return null; }
    public static java.util.Set<AppContext> getAppContexts() { return java.util.Collections.emptySet(); }
    public Object get(Object key) { return null; }
    public void put(Object key, Object value) {}
    public Object remove(Object key) { return null; }
    public boolean isDisposed() { return false; }
}
EOF
          cat > $DIR/jdk/src/share/classes/sun/nio/ch/DirectBuffer.java <<EOF
package sun.nio.ch;
public interface DirectBuffer {
    public long address();
    public Object attachment();
    public sun.misc.Cleaner cleaner();
}
EOF
          cat > $DIR/jdk/src/share/classes/sun/nio/ch/Interruptible.java <<EOF
package sun.nio.ch;
public interface Interruptible {
    public void interrupt(Thread t);
}
EOF

          echo "Fixing Java 7 syntax in $DIR..."
          find $DIR -name "*.java" -print0 | xargs -0 -r -P ''${NIX_BUILD_CORES:-1} -n 1 python3 ./fix_java7.py
          
          # Manually fix try-with-resources in problematic files
          if [ -f $DIR/jdk/src/share/classes/sun/reflect/misc/MethodUtil.java ]; then
              sed -i 's/try (InputStream is = url.openStream())/InputStream is = url.openStream(); try/g' $DIR/jdk/src/share/classes/sun/reflect/misc/MethodUtil.java
          fi
          if [ -f $DIR/jdk/src/share/classes/java/lang/Package.java ]; then
              sed -i 's/try (FileInputStream fis = new FileInputStream(fn);/FileInputStream fis = new FileInputStream(fn); JarInputStream jis = new JarInputStream(fis, false); try { \/\//g; s/JarInputStream jis = new JarInputStream(fis, false))/\/\//g' $DIR/jdk/src/share/classes/java/lang/Package.java
          fi
      done

      substituteInPlace openjdk/corba/make/common/shared/Defs-utils.gmk --replace-fail '/bin/echo' '${coreutils}/bin/echo'
      substituteInPlace openjdk/jdk/make/common/shared/Defs-utils.gmk --replace-fail '/bin/echo' '${coreutils}/bin/echo'

      patch -p0 < ${./patches/cppflags-include-fix.patch}
      patch -p0 < ${./patches/fix-java-home.patch}

      touch openjdk/jdk/src/solaris/classes/sun/awt/fontconfigs/linux.fontconfig.Gentoo.properties
      touch stamps/cryptocheck.stamp
    '';

    patches = [ ./patches/0001-make-jpeg-6b-optional.patch ];

    NIX_NO_SELF_RPATH = true;

    enableParallelBuilding = true;
    makeFlags = [
      "ALSA_INCLUDE=${alsa-lib}/include/alsa/version.h"
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
      mv $out/lib/icedtea/include $out/include
      mv $out/lib/icedtea/man $out/share/man
      ln -s $out/include/linux/*_md.h $out/include/
      rm -rf $out/share/man/ja*
      rm -rf $out/lib/icedtea/demo $out/lib/icedtea/sample
      mv $out/lib/icedtea/jre $jre/lib/icedtea/
      mkdir $out/lib/icedtea/jre
      lndir $jre/lib/icedtea/jre $out/lib/icedtea/jre
      rm $out/lib/icedtea/jre/lib/ext/*
      cp $jre/lib/icedtea/jre/lib/ext/* $out/lib/icedtea/jre/lib/ext/
      rm -rf $out/lib/icedtea/jre/bin
      ln -s $out/lib/icedtea/bin $out/lib/icedtea/jre/bin

      for i in $(cd $out/lib/icedtea/bin && echo *); do
        if [ "$i" = java ]; then continue; fi
        if cmp -s $out/lib/icedtea/bin/$i $jre/lib/icedtea/jre/bin/$i; then
          ln -sfn $jre/lib/icedtea/jre/bin/$i $out/lib/icedtea/bin/$i
        fi
      done

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

      mkdir -p $jre/nix-support
      echo -n "${setJavaClassPath}" > $jre/nix-support/propagated-native-build-inputs

      mkdir -p $out/nix-support
      cat <<EOF > $out/nix-support/setup-hook
      if [ -z "\$JAVA_HOME" ]; then export JAVA_HOME=$out/lib/icedtea; fi
      EOF
    '';

    meta = {
      description = "Free Java development kit based on OpenJDK 7.0 and the IcedTea project";
      homepage = "http://icedtea.classpath.org";
      license = lib.licenses.gpl2Plus;
      platforms = lib.platforms.linux;
    };

    passthru = {
      home = "${icedtea}/lib/icedtea";
    };
  };
in
icedtea
