# maven

## a
still not helpful
```
mvn se.vandmo:dependency-lock-maven-plugin:lock
jq -s '
  def entry($g; $a; $t; $v):
    {
      key: "\($g):\($a):\($t):\($v)",
      value: {
        layout: (($g | gsub("\\."; "/")) + "/" + $a + "/" + $v + "/" + $a + "-" + $v + "." + $t),
        url: ("https://repo.maven.apache.org/maven2/" + ($g | gsub("\\."; "/")) + "/" + $a + "/" + $v + "/" + $a + "-" + $v + "." + $t)
      }
    };

  {
    dependencies:
      (
        [ .[] | .dependencies[] as $d
          | entry($d.groupId; $d.artifactId; $d.type; $d.version),
            entry($d.groupId; $d.artifactId; "pom"; $d.version)
        ]
        | unique_by(.key)
        | from_entries
      )
  }
' ./dependencies-lock.json ./*/dependencies-lock.json > merged-dependencies.json
```

## from .m2

```
rm -fr ~/.m2
nix-shell -p jdk11 maven
git checkout maven-3.9.14
mvn -DskipITs -Dcpd.skip=true -Dpmd.skip=true -Dcheckstyle.skip=true -DskipTests -Dmaven.test.skip=true -Dspotless.apply.skip=true -Dspotless.check.skip=true -Drat.skip=true -Denforcer.skip=true install
```

use ../maven_3_3_9/m2.py
