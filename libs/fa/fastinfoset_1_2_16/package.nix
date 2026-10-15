{ maven_source_jar_common }:
maven_source_jar_common {
  groupId = "com.sun.xml.fastinfoset";
  artifactId = "FastInfoset";
  version = "1.2.16";
  srcHash = "sha256-tkggl5ejJxQNb6Ts94onb2E+ySxdnM1uelH/cZdrhLA=";
  pomHash = "sha256-4UfSWKtuZpH3BZmpUkAObmx1WPjJwCjb4b4jF4MI6DA=";
  testClass = "FastInfosetTest";
  testSource = ''
    import org.junit.Test;
    import static org.junit.Assert.*;
    import com.sun.xml.fastinfoset.sax.SAXDocumentSerializer;
    import com.sun.xml.fastinfoset.sax.SAXDocumentParser;
    import java.io.*;

    public class FastInfosetTest {
        @Test
        public void testFastInfosetEncoderDecoder() throws Exception {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            SAXDocumentSerializer serializer = new SAXDocumentSerializer();
            serializer.setOutputStream(baos);
            serializer.startDocument();
            serializer.endDocument();
            assertTrue(baos.size() > 0);

            SAXDocumentParser parser = new SAXDocumentParser();
            assertNotNull(parser);
        }
    }
  '';
}
