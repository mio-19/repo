{ maven_source_jar_common }:
maven_source_jar_common {
  groupId = "org.apache.httpcomponents";
  artifactId = "httpcore";
  version = "4.4.16";
  srcHash = "sha256-cF+M82cQk7bB2xa79pcafvQA44GXhPGvU+W8Pme1qaA=";
  pomHash = "sha256-PLrYSbNdrP5s7DGtraLGI8AmwyYRQbDSbux+OZxs1/o=";
  testClass = "HttpCoreTest";
  testSource = ''
    import org.junit.Test;
    import static org.junit.Assert.*;
    import org.apache.http.*;
    import org.apache.http.message.*;
    import org.apache.http.entity.*;

    public class HttpCoreTest {
        @Test
        public void testBasicHttpRequest() {
            HttpRequest request = new BasicHttpRequest("GET", "/index.html", HttpVersion.HTTP_1_1);
            assertEquals("GET", request.getRequestLine().getMethod());
            assertEquals("/index.html", request.getRequestLine().getUri());
            assertEquals(HttpVersion.HTTP_1_1, request.getProtocolVersion());
        }

        @Test
        public void testBasicHttpResponse() {
            HttpResponse response = new BasicHttpResponse(HttpVersion.HTTP_1_1, HttpStatus.SC_OK, "OK");
            assertEquals(200, response.getStatusLine().getStatusCode());
            assertEquals("OK", response.getStatusLine().getReasonPhrase());
        }

        @Test
        public void testStringEntity() throws Exception {
            StringEntity entity = new StringEntity("Hello World", "UTF-8");
            assertEquals(11, entity.getContentLength());
            assertTrue(entity.isRepeatable());
        }
    }
  '';
}
