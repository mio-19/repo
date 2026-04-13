# maven

## remove .asc
```
jq 'walk(
  if type == "object"
  then with_entries(select(.key | endswith(".asc") | not))
  else .
  end
)'
```
```
jq 'walk(
  if type == "object"
  then with_entries(select(.key | endswith(".module") | not))
  else .
  end
)'
```
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