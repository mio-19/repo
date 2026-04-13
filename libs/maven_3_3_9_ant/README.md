
## from .m2 - WIP

```
rm -fr ~/.m2
nix-shell -p jdk8 ant
git checkout maven-3.3.9
find . -type f -name '*.xml' -exec sed -i 's|http://repo1\.maven\.org/maven2|https://repo1.maven.org/maven2|g' {} +
ant -Dmaven.home="$PWD/out/apache-maven-3.3.9"
```

use ../maven_3_3_9_mvn/m2.py