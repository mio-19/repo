{ maven_source_jar_common }:
maven_source_jar_common {
  groupId = "org.jetbrains";
  artifactId = "annotations";
  version = "13.0";
  srcHash = "sha256-QqXhRLjoHVDWkT0QB7aV5i5hRwUmjYz58T29xHjCxo4=";
  pomHash = "sha256-llrrK+3/NpgZvd4b96CzuJuCR91pyIuGN112Fju4w5c=";
  testClass = "AnnotationsTest";
  testSource = ''
    import org.junit.Test;
    import static org.junit.Assert.*;
    import java.lang.annotation.Retention;
    import java.lang.annotation.RetentionPolicy;
    import org.jetbrains.annotations.Nullable;
    import org.jetbrains.annotations.NotNull;

    public class AnnotationsTest {
        @Test
        public void testNullableRetention() {
            Retention r = Nullable.class.getAnnotation(Retention.class);
            assertNotNull(r);
            assertEquals(RetentionPolicy.CLASS, r.value());
        }

        @Test
        public void testNotNullRetention() {
            Retention r = NotNull.class.getAnnotation(Retention.class);
            assertNotNull(r);
            assertEquals(RetentionPolicy.CLASS, r.value());
        }
    }
  '';
}
