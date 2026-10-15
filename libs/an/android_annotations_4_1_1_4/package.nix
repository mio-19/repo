{ maven_source_jar_common }:
maven_source_jar_common {
  groupId = "com.google.android";
  artifactId = "annotations";
  version = "4.1.1.4";
  srcHash = "sha256-6bZnqpWN946hrRFfe7rBilhpwxKLHVBD/rNgsM/OnUA=";
  pomHash = "sha256-5LtUdTw2onoOXXAVSlA0/t2P6sQoIpUDS/1IPWx6rng=";
  testClass = "AndroidAnnotationsTest";
  testSource = ''
    import org.junit.Test;
    import static org.junit.Assert.*;
    import java.lang.annotation.*;
    import android.annotation.SuppressLint;
    import android.annotation.TargetApi;

    public class AndroidAnnotationsTest {
        @SuppressLint("NewApi")
        @TargetApi(21)
        static class ExampleClass {}

        @Test
        public void testRetention() {
            Retention r1 = SuppressLint.class.getAnnotation(Retention.class);
            assertNotNull(r1);
            assertEquals(RetentionPolicy.CLASS, r1.value());

            Retention r2 = TargetApi.class.getAnnotation(Retention.class);
            assertNotNull(r2);
            assertEquals(RetentionPolicy.CLASS, r2.value());
        }
    }
  '';
}
