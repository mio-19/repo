# lock

```
rm -fr ~/.m2
nix-shell -p jdk8 ant
sed -i 's|<contains string="${ant.version}" substring="1.1"></contains>||g' build.xml
#ant install
sed -i 's|http://repo1.maven.org/maven2|https://repo1.maven.org/maven2|g' build.gradle
sed -i 's|http\\://gradle.artifactoryonline.com/gradle/distributions|https://services.gradle.org/distributions/|g' gradle/wrapper/gradle-wrapper.properties
sed -i 's|mavenCentral()|mavenRepo urls: ["https://repo1.maven.org/maven2"]|g' gradle/upload.gradle
sh gradlew test
tee ~/.m2/settings.xml << 'EOF'
<settings>
  <mirrors>
    <mirror>
      <id>central-https</id>
      <mirrorOf>central,codehaus,codehaus.snapshots</mirrorOf>
      <name>Maven Central HTTPS</name>
      <url>https://repo.maven.apache.org/maven2</url>
    </mirror>
  </mirrors>
</settings>
EOF
sed -i 's|\bParameter\b|org.codehaus.groovy.ast.Parameter|g' src/main/org/codehaus/groovy/vmplugin/v5/Java5.java
ant createJars
```

use ../maven_3_3_9/m2.py
```
python ../maven_3_3_9/m2.py > linux-m2.json
../maven_3_9_14/refresh-hashes.sh linux-m2.json
```