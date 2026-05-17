{
  stdenv,
  runCommand,
  jamvm-2_0_0,
  ecj-bootstrap-3_2_2,
  gnu-classpath-0_99,
  fastjar,
  zip,
  unzip,
  makeWrapper,
}:
let
  jdk5 = runCommand "jdk5-bootstrap" {
    nativeBuildInputs = [ makeWrapper zip ];
    passthru.home = "${jdk5}";
  } ''
    mkdir -p $out/bin $out/lib $out/jre/lib
    
    # Wrap java properly using JamVM 2.0.0
    makeWrapper ${jamvm-2_0_0}/bin/jamvm $out/bin/java \
      --add-flags "-Xbootclasspath:${jamvm-2_0_0}/share/jamvm/classes.zip:$out/jre/lib/rt.jar"

    # Robust javac wrapper that handles IcedTea flags
    cat > $out/bin/javac <<EOF
    #!${stdenv.shell}
    declare -a args
    # Default bootclasspath (our rt.jar has the injected classes)
    BCP="${jamvm-2_0_0}/share/jamvm/classes.zip:$out/jre/lib/rt.jar"
    HAS_BCP=
    
    # Parse arguments
    while [ "\$#" -gt 0 ]; do
      case "\$1" in
        -source|-target)
          # Force 1.6 as ECJ 3.2.2 doesn't support 7
          args+=("\$1" "1.6")
          shift 2
          ;;
        -bootclasspath)
          if [ "\$2" = "" ] || [ -z "\$2" ]; then
            # Ignore empty bootclasspath from IcedTea
            shift 2
          else
            args+=("\$1" "\$2")
            HAS_BCP=1
            shift 2
          fi
          ;;
        -J-XX:*)
          # Filter out -XX flags that JamVM doesn't understand
          shift
          ;;
        -XD*)
          # Ignore -XD flags
          shift
          ;;
        *)
          args+=("\$1")
          shift
          ;;
      esac
    done
    
    # Run ECJ with our JVM
    if [ -n "\$HAS_BCP" ]; then
      exec $out/bin/java -classpath ${ecj-bootstrap-3_2_2}/share/java/ecj-bootstrap.jar \
        org.eclipse.jdt.internal.compiler.batch.Main "\''${args[@]}"
    else
      exec $out/bin/java -classpath ${ecj-bootstrap-3_2_2}/share/java/ecj-bootstrap.jar \
        org.eclipse.jdt.internal.compiler.batch.Main -bootclasspath "\$BCP" "\''${args[@]}"
    fi
    EOF
    chmod +x $out/bin/javac

    classpathTool() {
      substitute ${../openjdk-common/classpath-tool.sh.in} "$out/bin/$1" \
        --subst-var-by shell "${stdenv.shell}" \
        --subst-var-by java "$out/bin/java" \
        --subst-var-by classpath "${gnu-classpath-0_99}" \
        --subst-var-by toolPkg "$2" \
        --subst-var-by mainClass "$3"
      chmod +x "$out/bin/$1"
    }

    classpathTool javah javah Main
    classpathTool rmic rmic Main
    classpathTool rmid rmid Main
    classpathTool orbd orbd Main
    classpathTool rmiregistry rmiregistry Main
    classpathTool native2ascii native2ascii Native2ASCII

    ln -s ${fastjar}/bin/fastjar $out/bin/jar
    
    # Copy jars instead of symlinking
    cp ${gnu-classpath-0_99}/share/classpath/tools.zip $out/lib/tools.jar
    cp ${gnu-classpath-0_99}/share/classpath/glibj.zip $out/jre/lib/rt.jar
    chmod u+w $out/lib/tools.jar $out/jre/lib/rt.jar
    
    # Inject Java 7 and internal sun.* classes into rt.jar
    mkdir -p java/lang java/io java/util java/nio/file/attribute sun/awt sun/reflect sun/misc sun/nio/ch sun/security/action
    cat > java/lang/AutoCloseable.java <<EOF
    package java.lang;
    public interface AutoCloseable {
        void close() throws Exception;
    }
    EOF
    cat > java/lang/ReflectiveOperationException.java <<EOF
    package java.lang;
    public class ReflectiveOperationException extends Exception {
        public ReflectiveOperationException() { super(); }
        public ReflectiveOperationException(String message) { super(message); }
        public ReflectiveOperationException(String message, Throwable cause) { super(message, cause); }
        public ReflectiveOperationException(Throwable cause) { super(cause); }
    }
    EOF
    cat > java/io/Closeable.java <<EOF
    package java.io;
    public interface Closeable extends java.lang.AutoCloseable {
        void close() throws java.io.IOException;
    }
    EOF
    cat > java/util/Objects.java <<EOF
    package java.util;
    public final class Objects {
        private Objects() { throw new AssertionError("No java.util.Objects instances for you!"); }
        public static boolean equals(Object a, Object b) {
            return (a == b) || (a != null && a.equals(b));
        }
        public static int hash(Object... values) {
            return Arrays.hashCode(values);
        }
        public static int hashCode(Object o) {
            return o != null ? o.hashCode() : 0;
        }
        public static <T> T requireNonNull(T obj) {
            if (obj == null) throw new NullPointerException();
            return obj;
        }
    }
    EOF
    cat > java/nio/file/Path.java <<EOF
    package java.nio.file;
    public interface Path {}
    EOF
    cat > java/nio/file/FileVisitor.java <<EOF
    package java.nio.file;
    public interface FileVisitor<T> {
        FileVisitResult preVisitDirectory(T dir, java.nio.file.attribute.BasicFileAttributes attrs) throws java.io.IOException;
        FileVisitResult visitFile(T file, java.nio.file.attribute.BasicFileAttributes attrs) throws java.io.IOException;
        FileVisitResult visitFileFailed(T file, java.io.IOException exc) throws java.io.IOException;
        FileVisitResult postVisitDirectory(T dir, java.io.IOException exc) throws java.io.IOException;
    }
    EOF
    cat > java/nio/file/FileVisitResult.java <<EOF
    package java.nio.file;
    public enum FileVisitResult { CONTINUE, TERMINATE, SKIP_SUBTREE, SKIP_SIBLINGS }
    EOF
    cat > java/nio/file/SimpleFileVisitor.java <<EOF
    package java.nio.file;
    public class SimpleFileVisitor<T> implements FileVisitor<T> {
        public FileVisitResult preVisitDirectory(T dir, java.nio.file.attribute.BasicFileAttributes attrs) throws java.io.IOException { return FileVisitResult.CONTINUE; }
        public FileVisitResult visitFile(T file, java.nio.file.attribute.BasicFileAttributes attrs) throws java.io.IOException { return FileVisitResult.CONTINUE; }
        public FileVisitResult visitFileFailed(T file, java.io.IOException exc) throws java.io.IOException { throw exc; }
        public FileVisitResult postVisitDirectory(T dir, java.io.IOException exc) throws java.io.IOException { if (exc != null) throw exc; return FileVisitResult.CONTINUE; }
    }
    EOF
    cat > java/nio/file/attribute/BasicFileAttributes.java <<EOF
    package java.nio.file.attribute;
    public interface BasicFileAttributes {}
    EOF
    cat > sun/awt/AppContext.java <<EOF
    package sun.awt;
    import java.util.*;
    public final class AppContext {
        private static AppContext instance = new AppContext();
        private Map<Object, Object> table = new HashMap<Object, Object>();
        public static AppContext getAppContext() { return instance; }
        public static Set<AppContext> getAppContexts() { return Collections.singleton(instance); }
        public Object get(Object key) { return table.get(key); }
        public void put(Object key, Object val) { table.put(key, val); }
        public void remove(Object key) { table.remove(key); }
    }
    EOF
    cat > sun/reflect/ReflectionFactory.java <<EOF
    package sun.reflect;
    import java.lang.reflect.*;
    public class ReflectionFactory {
        private static ReflectionFactory instance = new ReflectionFactory();
        public static ReflectionFactory getReflectionFactory() { return instance; }
        public static class GetReflectionFactoryAction implements java.security.PrivilegedAction<ReflectionFactory> {
            public ReflectionFactory run() { return getReflectionFactory(); }
        }
        public Constructor<?> newConstructorForSerialization(Class<?> type, Constructor<?> constructor) { return null; }
    }
    EOF
    cat > sun/misc/SharedSecrets.java <<EOF
    package sun.misc;
    public class SharedSecrets {
        private static JavaSecurityAccess javaSecurityAccess;
        public static JavaSecurityAccess getJavaSecurityAccess() { return javaSecurityAccess; }
        public static void setJavaSecurityAccess(JavaSecurityAccess jsa) { javaSecurityAccess = jsa; }
    }
    EOF
    cat > sun/misc/JavaSecurityAccess.java <<EOF
    package sun.misc;
    public interface JavaSecurityAccess {
        <T> T doPrivileged(java.security.PrivilegedAction<T> action, java.security.AccessControlContext acc, java.security.Permission... perms);
    }
    EOF
    cat > sun/misc/Cleaner.java <<EOF
    package sun.misc;
    public class Cleaner extends java.lang.ref.PhantomReference<Object> {
        private Cleaner(Object referent, Runnable thunk) { super(referent, null); }
        public static Cleaner create(Object ob, Runnable thunk) { return new Cleaner(ob, thunk); }
        public void clean() {}
    }
    EOF
    cat > sun/misc/VM.java <<EOF
    package sun.misc;
    public class VM {
        public static boolean isDirectMemoryPageAligned() { return false; }
        public static void initialize() {}
    }
    EOF
    cat > sun/nio/ch/DirectBuffer.java <<EOF
    package sun.nio.ch;
    public interface DirectBuffer {
        public long address();
        public Object attachment();
        public sun.misc.Cleaner cleaner();
    }
    EOF
    cat > sun/security/action/GetPropertyAction.java <<EOF
    package sun.security.action;
    public class GetPropertyAction implements java.security.PrivilegedAction<String> {
        private String theProp;
        public GetPropertyAction(String prop) { this.theProp = prop; }
        public String run() { return System.getProperty(theProp); }
    }
    EOF
    # Compile all injected classes using raw JamVM/ECJ
    find java sun -name "*.java" > sources.txt
    ${jamvm-2_0_0}/bin/jamvm -Xbootclasspath:${jamvm-2_0_0}/share/jamvm/classes.zip:${gnu-classpath-0_99}/share/classpath/glibj.zip \
      -classpath ${ecj-bootstrap-3_2_2}/share/java/ecj-bootstrap.jar \
      org.eclipse.jdt.internal.compiler.batch.Main \
      -source 1.5 -target 1.5 @sources.txt
    # Add to rt.jar
    find java sun -name "*.class" > classes.txt
    ${zip}/bin/zip -u $out/jre/lib/rt.jar $(cat classes.txt)
    
    # Add dummy javadoc
    touch $out/bin/javadoc
    chmod +x $out/bin/javadoc
  '';
in
jdk5
