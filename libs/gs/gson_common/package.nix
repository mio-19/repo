# for gson 2.2.4 ~ 2.11.0
{
  fetchFromGitHub,
  jdk21_headless,
  junit_4,
  java-hamcrest,
  lib,
  stdenv,
}:
{
  version,
  tag ? "gson-parent-${version}",
  hash,
  buildConfig ? true,
  gsonDir ? true,
  doCheck ? true,
  extraClasspath ? [ ],
  disabledTests ? [ ],
}:
let
  prefix = if gsonDir then "gson/" else "";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gson";
  inherit version;

  src = fetchFromGitHub {
    owner = "google";
    repo = "gson";
    inherit tag hash;
  };

  nativeBuildInputs = [ jdk21_headless ];
  nativeCheckInputs = lib.optionals doCheck [
    junit_4
    java-hamcrest
  ];

  inherit doCheck;

  buildPhase = ''
    runHook preBuild

    find "$src/${prefix}src/main/java" -name '*.java' ! -name 'module-info.java' > sources.txt
    ${lib.optionalString buildConfig ''
      mkdir -p generated/src/main/java/com/google/gson/internal
      substitute $src/${prefix}src/main/java-templates/com/google/gson/internal/GsonBuildConfig.java generated/src/main/java/com/google/gson/internal/GsonBuildConfig.java \
        --replace-fail '${"$"}{project.version}' "${finalAttrs.version}"
      find generated -name '*.java' >> sources.txt
    ''}
    mkdir classes
    javac --release 8 -encoding UTF-8 \
      ${lib.optionalString (extraClasspath != [ ]) "-cp ${lib.concatStringsSep ":" extraClasspath}"} \
      -d classes @sources.txt

    cd classes
    jar cf "../gson-${finalAttrs.version}.jar" .
    cd ..

    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck

    mkdir -p test-src test-classes
    cat << 'EOF' > test-src/GsonUnitTest.java
    import org.junit.Test;
    import static org.junit.Assert.*;
    import com.google.gson.Gson;
    import com.google.gson.JsonObject;
    import com.google.gson.JsonParser;
    import com.google.gson.JsonArray;
    import com.google.gson.JsonPrimitive;

    public class GsonUnitTest {
        @Test
        public void testBasicSerialization() {
            Gson gson = new Gson();
            assertEquals("[1,2,3]", gson.toJson(new int[] { 1, 2, 3 }));
            int[] arr = gson.fromJson("[1,2,3]", int[].class);
            assertArrayEquals(new int[] { 1, 2, 3 }, arr);
        }

        @Test
        public void testJsonObjectAndParser() {
            JsonObject obj = new JsonObject();
            obj.addProperty("key", "value");
            obj.addProperty("num", 123);
            String json = obj.toString();
            JsonObject parsed = new Gson().fromJson(json, JsonObject.class);
            assertEquals("value", parsed.get("key").getAsString());
            assertEquals(123, parsed.get("num").getAsInt());
            JsonObject parsed2 = new JsonParser().parse(json).getAsJsonObject();
            assertEquals("value", parsed2.get("key").getAsString());
        }

        @Test
        public void testJsonArray() {
            JsonArray arr = new JsonArray();
            arr.add(new JsonPrimitive("a"));
            arr.add(new JsonPrimitive("b"));
            assertEquals(2, arr.size());
            assertEquals("a", arr.get(0).getAsString());
            assertEquals("b", arr.get(1).getAsString());
        }
    }
    EOF

    ${lib.concatMapStringsSep "\n" (testMethod: ''
      substituteInPlace test-src/GsonUnitTest.java \
        --replace-fail 'public void ${testMethod}()' '@org.junit.Ignore public void ${testMethod}()'
    '') disabledTests}

    javac --release 8 -encoding UTF-8 \
      -cp "./gson-${finalAttrs.version}.jar:${junit_4}/share/java/junit.jar:${java-hamcrest}/share/java/hamcrest-3.0.jar${
        lib.optionalString (extraClasspath != [ ]) ":${lib.concatStringsSep ":" extraClasspath}"
      }" \
      -d test-classes test-src/GsonUnitTest.java

    java -cp "test-classes:./gson-${finalAttrs.version}.jar:${junit_4}/share/java/junit.jar:${java-hamcrest}/share/java/hamcrest-3.0.jar${
      lib.optionalString (extraClasspath != [ ]) ":${lib.concatStringsSep ":" extraClasspath}"
    }" \
      org.junit.runner.JUnitCore GsonUnitTest

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    install -Dm644 "./gson-${finalAttrs.version}.jar" "$out/gson-${finalAttrs.version}.jar"
    ${lib.optionalString gsonDir ''
      install -Dm644 "$src/${prefix}pom.xml" "$out/gson-${finalAttrs.version}.pom"
    ''}
    install -Dm644 "$src/pom.xml" "$out/gson-parent-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Java serialization and deserialization library for JSON";
    homepage = "https://github.com/google/gson";
    sourceProvenance = with sourceTypes; [ fromSource ];
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
