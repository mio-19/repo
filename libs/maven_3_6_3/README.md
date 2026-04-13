# maven

## from .m2

```
rm -fr ~/.m2
nix-shell -p jdk11 maven
git checkout maven-3.6.3
mvn clean
mvn package
mvn install
```

use ../maven_3_3_9/m2.py
```
python ../maven_3_3_9/m2.py > linux-m2.json
jq '.dependencies |= with_entries(select(.key | test("^org\\.apache\\.maven[^:]*:[^:]+:[^:]+:3\\.6\\.3(:[^:]+)?$") | not))' linux-m2.json > tmp && mv tmp linux-m2.json
```