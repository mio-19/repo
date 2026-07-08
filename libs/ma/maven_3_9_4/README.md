# maven

## from .m2

```
rm -fr ~/.m2
nix-shell -p jdk11 maven
git checkout maven-3.9.4
mvn clean
mvn package
mvn install
```

use ../maven_3_3_9/m2.py
```
python ../maven_3_3_9/m2.py > linux-m2.json
# also need to  remove 3.9.4 entries from linux-m2.json
jq '.dependencies |= with_entries(select(.key | test("^org\\.apache\\.maven[^:]*:[^:]+:[^:]+:3\\.9\\.4(:[^:]+)?$") | not))' linux-m2.json > tmp && mv tmp linux-m2.json
../maven_3_9_14/refresh-hashes.sh linux-m2.json
```