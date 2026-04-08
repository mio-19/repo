{
  mk-apk-package,
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  go_1_25,
  gitMinimal,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-35
        s.build-tools-35-0-1
        s.ndk-27-3-13750724
      ]);

      xMobileSrc = fetchFromGitHub {
        owner = "golang";
        repo = "mobile";
        rev = "35478a0c49da";
        hash = "sha256-znEqH+8jdoW3QkpH/apJwCLZ72R22WQoz9J2RA/r7+E=";
      };

      singBoxSrc = fetchFromGitHub {
        owner = "MatsuriDayo";
        repo = "sing-box";
        rev = "aed32ee3066cdbc7d471e3e0415c5134088962df";
        hash = "sha256-fKRXthB4raLWLVll0qHgN9DwnqTu4JRHI1FGYTbYrlw=";
      };

      libnekoSrc = fetchFromGitHub {
        owner = "MatsuriDayo";
        repo = "libneko";
        rev = "1c47a3af71990a7b2192e03292b4d246c308ef0b";
        hash = "sha256-9ftRh8K4z7m265dbEwWSBeNiwznnNl/FolVv4rZ4C8E=";
      };

      libcoreGoModCache = stdenvNoCC.mkDerivation {
        pname = "nekobox-libcore-go-mod-cache";
        version = "1.4.2";
        src = fetchFromGitHub {
          owner = "MatsuriDayo";
          repo = "NekoBoxForAndroid";
          tag = "1.4.2";
          hash = "sha256-vbuqD34NuKxnxfsGaInCm01EEv873i4cctFX3+2EEoA=";
        };

        nativeBuildInputs = [
          go_1_25
          gitMinimal
        ];
        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = "sha256-UJfHrjgQ+oOzW9gA86A2lpR0ayE06n19SfA3etVJipI=";
        dontConfigure = true;
        dontFixup = true;

        buildPhase = ''
          runHook preBuild
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"
          export GOPATH="$TMPDIR/go"
          export GOBIN="$TMPDIR/go/bin"
          export GOCACHE="$TMPDIR/go-build-cache"
          export GOMODCACHE="$TMPDIR/go-mod-cache"
          export GOPROXY=https://proxy.golang.org,direct
          export GOSUMDB=sum.golang.org
          export CGO_ENABLED=0

          cp -R "$src" source
          chmod -R u+w source
          cd source
          cp -R ${xMobileSrc} x-mobile
          cp -R ${singBoxSrc} sing-box
          cp -R ${libnekoSrc} libneko
          (
            cd x-mobile
            chmod -R u+w .
            substituteInPlace cmd/gomobile/bind_androidapp.go \
              --replace-fail 'if err := goModTidyAt(srcDir, env); err != nil {' 'if false {'
            substituteInPlace cmd/gomobile/build.go \
              --replace-fail 'if gmc, err := goModCachePath(); err == nil {' 'if false {' \
              --replace-fail 'env = append([]string{"GOMODCACHE=" + gmc}, env...)' 'env = append([]string{}, env...)'
            go mod edit \
              -require=golang.org/x/mod@v0.27.0 \
              -require=golang.org/x/sync@v0.16.0 \
              -require=golang.org/x/tools@v0.36.0 \
              -require=golang.org/x/sys@v0.35.0 \
              -require=golang.org/x/image@v0.25.0
            go mod download
            go get golang.org/x/tools/go/packages/packagestest
            go get ./cmd/gomobile ./cmd/gobind
            go list -deps -test \
              -f '{{if and .Module .Module.Path .Module.Version}}{{.Module.Path}}@{{.Module.Version}}{{end}}' \
              ./cmd/gomobile ./cmd/gobind \
              | sort -u \
              | while read -r module; do
                  if [ -n "$module" ]; then
                    go mod download "$module"
                  fi
                done
            go install ./cmd/gomobile ./cmd/gobind
          )
          substituteInPlace libcore/go.mod \
            --replace-fail '../../libneko' '../libneko' \
            --replace-fail '../../sing-box' '../sing-box' \
            --replace-fail 'golang.org/x/mobile v0.0.0-20231108233038-35478a0c49da' 'golang.org/x/mobile v0.0.0-00010101000000-000000000000'
          cd libcore
          go mod edit -replace=golang.org/x/mobile=../x-mobile
          go mod download all
          mkdir -p "$TMPDIR/gomobile-compat"
          cat > "$TMPDIR/gomobile-compat/go.mod" <<'EOF'
          module gomobile-compat

          go 1.23

          require golang.org/x/mobile v0.0.0-20201217150744-e6ae53a27f4f
          EOF
          (
            cd "$TMPDIR/gomobile-compat"
            go mod download all
          )
          go mod download \
            github.com/stretchr/objx@v0.5.2 \
            github.com/stretchr/testify@v1.10.0 \
            github.com/stretchr/testify@v1.2.2 \
            github.com/BurntSushi/toml@v0.3.1 \
            github.com/BurntSushi/xgb@v0.0.0-20160522181843-27f122750802 \
            dmitri.shuralyov.com/app/changes@v0.0.0-20180602232624-0a106ad413e3 \
            dmitri.shuralyov.com/html/belt@v0.0.0-20180602232347-f7d459c86be0 \
            dmitri.shuralyov.com/service/change@v0.0.0-20181023043359-a85b471d5412 \
            dmitri.shuralyov.com/state@v0.0.0-20180228185332-28bcc343414c \
            golang.org/x/xerrors@v0.0.0-20200804184101-5ec99f83aff1 \
            gopkg.in/check.v1@v1.0.0-20201130134442-10cb98267c6c \
            cel.dev/expr@v0.23.0 \
            cloud.google.com/go@v0.34.0 \
            cloud.google.com/go@v0.31.0 \
            cloud.google.com/go@v0.37.0 \
            cloud.google.com/go@v0.26.0 \
            github.com/buger/jsonparser@v0.0.0-20181115193947-bf1c66bbce23 \
            github.com/beorn7/perks@v0.0.0-20180321164747-3a771d992973 \
            github.com/anmitsu/go-shlex@v0.0.0-20161002113705-648efa622239 \
            github.com/bradfitz/go-smtpd@v0.0.0-20170404230938-deb6d6237625 \
            github.com/client9/misspell@v0.3.4 \
            github.com/coreos/go-systemd@v0.0.0-20181012123002-c6f51f82210d \
            github.com/davecgh/go-spew@v1.1.1 \
            github.com/dustin/go-humanize@v1.0.0 \
            github.com/flynn/go-shlex@v0.0.0-20150515145356-3f9db97f8568 \
            github.com/fsnotify/fsnotify@v1.4.7 \
            github.com/gliderlabs/ssh@v0.1.1 \
            github.com/ghodss/yaml@v1.0.0 \
            github.com/gogo/protobuf@v1.1.1 \
            github.com/go-errors/errors@v1.0.1 \
            github.com/golang/mock@v1.2.0 \
            github.com/golang/protobuf@v1.2.0 \
            github.com/golang/protobuf@v1.3.1 \
            github.com/google/go-github@v17.0.0+incompatible \
            github.com/google/go-querystring@v1.0.0 \
            github.com/golang/glog@v0.0.0-20160126235308-23def4e6c14b \
            github.com/golang/mock@v1.1.1 \
            github.com/golang/lint@v0.0.0-20180702182130-06c8688daad7 \
            github.com/json-iterator/go@v1.1.6 \
            github.com/lunixbochs/vtclean@v1.0.0 \
            github.com/mailru/easyjson@v0.0.0-20190312143242-1de009706dbe \
            github.com/matttproud/golang_protobuf_extensions@v1.0.1 \
            github.com/modern-go/concurrent@v0.0.0-20180306012644-bacd9c7ef1dd \
            github.com/modern-go/reflect2@v1.0.1 \
            github.com/grpc-ecosystem/grpc-gateway@v1.5.0 \
            github.com/gopherjs/gopherjs@v0.0.0-20181017120253-0766667cb4d1 \
            github.com/gregjones/httpcache@v0.0.0-20180305231024-9cad4c3443a7 \
            github.com/kisielk/gotool@v1.0.0 \
            github.com/jellevandenhooff/dkim@v0.0.0-20150330215556-f50fe3d243e1 \
            github.com/kr/pty@v1.1.3 \
            github.com/kr/pty@v1.1.1 \
            github.com/microcosm-cc/bluemonday@v1.0.1 \
            github.com/neelance/astrewrite@v0.0.0-20160511093645-99348263ae86 \
            github.com/neelance/sourcemap@v0.0.0-20151028013722-8c68805598ab \
            github.com/openzipkin/zipkin-go@v0.1.1 \
            github.com/pkg/errors@v0.8.1 \
            github.com/go-logr/logr@v1.2.2 \
            github.com/go-logr/stdr@v1.2.2 \
            github.com/google/go-cmp@v0.2.0 \
            github.com/google/go-cmp@v0.5.2 \
            github.com/creack/pty@v1.1.9 \
            github.com/cpuguy83/go-md2man/v2@v2.0.6 \
            github.com/vishvananda/netns@v0.0.0-20200728191858-db3c7e526aae \
            github.com/kr/pretty@v0.2.1 \
            github.com/kr/pretty@v0.1.0 \
            github.com/kr/text@v0.2.0 \
            github.com/kr/text@v0.1.0 \
            github.com/jessevdk/go-flags@v1.4.0 \
            github.com/pmezard/go-difflib@v1.0.0 \
            github.com/prometheus/client_golang@v0.8.0 \
            github.com/prometheus/client_model@v0.0.0-20180712105110-5c3871d89910 \
            github.com/prometheus/common@v0.0.0-20180801064454-c7de2306084e \
            github.com/prometheus/procfs@v0.0.0-20180725123919-05ee40e3a273 \
            github.com/russross/blackfriday/v2@v2.1.0 \
            github.com/russross/blackfriday@v1.5.2 \
            github.com/sergi/go-diff@v1.0.0 \
            github.com/shurcooL/component@v0.0.0-20170202220835-f88ec8f54cc4 \
            github.com/shurcooL/events@v0.0.0-20181021180414-410e4ca65f48 \
            github.com/shurcooL/github_flavored_markdown@v0.0.0-20181002035957-2122de532470 \
            github.com/shurcooL/gofontwoff@v0.0.0-20180329035133-29b52fc0a18d \
            github.com/shurcooL/gopherjslib@v0.0.0-20160914041154-feb6d3990c2c \
            github.com/shurcooL/go@v0.0.0-20180423040247-9e1955d9fb6e \
            github.com/shurcooL/go-goon@v0.0.0-20170922171312-37c2f522c041 \
            github.com/shurcooL/highlight_diff@v0.0.0-20170515013008-09bb4053de1b \
            github.com/shurcooL/highlight_go@v0.0.0-20181028180052-98c3abbbae20 \
            github.com/shurcooL/home@v0.0.0-20181020052607-80b7ffcb30f9 \
            github.com/shurcooL/htmlg@v0.0.0-20170918183704-d01228ac9e50 \
            github.com/shurcooL/httperror@v0.0.0-20170206035902-86b7830d14cc \
            github.com/shurcooL/httpfs@v0.0.0-20171119174359-809beceb2371 \
            github.com/shurcooL/httpgzip@v0.0.0-20180522190206-b1c53ac65af9 \
            github.com/shurcooL/issues@v0.0.0-20181008053335-6292fdc1e191 \
            github.com/shurcooL/issuesapp@v0.0.0-20180602232740-048589ce2241 \
            github.com/shurcooL/notifications@v0.0.0-20181007000457-627ab5aea122 \
            github.com/shurcooL/octicon@v0.0.0-20181028054416-fa4f57f9efb2 \
            github.com/shurcooL/reactions@v0.0.0-20181006231557-f2e0b4ca5b82 \
            github.com/shurcooL/sanitized_anchor_name@v0.0.0-20170918181015-86672fcb3f95 \
            github.com/shurcooL/users@v0.0.0-20180125191416-49c67e49c537 \
            github.com/shurcooL/webdavfs@v0.0.0-20170829043945-18c3829fa133 \
            github.com/sourcegraph/annotate@v0.0.0-20160123013949-f4cad6c6324d \
            github.com/sourcegraph/syntaxhighlight@v0.0.0-20170531221838-bd320f5d308e \
            github.com/tarm/serial@v0.0.0-20180830185346-98f6abe2eb07 \
            github.com/viant/assertly@v0.4.8 \
            github.com/viant/toolbox@v0.24.0 \
            github.com/googleapis/gax-go@v2.0.0+incompatible \
            github.com/googleapis/gax-go/v2@v2.0.3 \
            github.com/google/btree@v0.0.0-20180813153112-4030bb1f1f0c \
            github.com/jstemmer/go-junit-report@v0.0.0-20190106144839-af01ea7f8024 \
            github.com/google/martian@v2.1.0+incompatible \
            github.com/google/pprof@v0.0.0-20181206194817-3ea8567a2e57 \
            go.opencensus.io@v0.18.0 \
            go4.org@v0.0.0-20180809161055-417644f6feb5 \
            git.apache.org/thrift.git@v0.0.0-20180902110319-2566ecd5d999 \
            golang.org/x/build@v0.0.0-20190111050920-041ab4dc3f9d \
            golang.org/x/lint@v0.0.0-20190227174305-5b3e6a55c961 \
            golang.org/x/lint@v0.0.0-20181026193005-c67002cb31c3 \
            golang.org/x/lint@v0.0.0-20180702182130-06c8688daad7 \
            golang.org/x/crypto@v0.0.0-20190313024323-a1f597ede03a \
            golang.org/x/crypto@v0.0.0-20190308221718-c2843e01d9a2 \
            golang.org/x/crypto@v0.0.0-20181030102418-4d3f4d9ffa16 \
            golang.org/x/exp@v0.0.0-20190731235908-ec7cb31e5a56 \
            golang.org/x/image@v0.0.0-20190227222117-0694c2d4d067 \
            golang.org/x/image@v0.0.0-20190802002840-cff245a6509b \
            golang.org/x/mobile@v0.0.0-20190312151609-d3739f865fa6 \
            golang.org/x/mobile@v0.0.0-20201217150744-e6ae53a27f4f \
            golang.org/x/mod@v0.1.0 \
            golang.org/x/mod@v0.1.1-0.20191209134235-331c550502dd \
            golang.org/x/net@v0.0.0-20190313220215-9f648a60d977 \
            golang.org/x/net@v0.0.0-20190108225652-1e06a53dbb7e \
            golang.org/x/net@v0.0.0-20190213061140-3a22650c66bd \
            golang.org/x/net@v0.0.0-20180826012351-8a410e7b638d \
            golang.org/x/net@v0.0.0-20181106065722-10aee1819953 \
            golang.org/x/net@v0.0.0-20180906233101-161cd47e91fd \
            golang.org/x/net@v0.0.0-20181029044818-c44066c5c816 \
            golang.org/x/net@v0.0.0-20180724234803-3673e40ba225 \
            golang.org/x/net@v0.33.0 \
            golang.org/x/oauth2@v0.0.0-20190226205417-e64efc72b421 \
            golang.org/x/oauth2@v0.0.0-20181203162652-d668ce993890 \
            golang.org/x/oauth2@v0.0.0-20180821212333-d2e6202438be \
            golang.org/x/oauth2@v0.0.0-20181017192945-9dcd33a902f4 \
            golang.org/x/perf@v0.0.0-20180704124530-6e6d33e29852 \
            golang.org/x/exp@v0.0.0-20190121172915-509febef88a4 \
            golang.org/x/sync@v0.0.0-20210220032951-036812b2e83c \
            golang.org/x/sync@v0.0.0-20181221193216-37e7f081c4d4 \
            golang.org/x/sync@v0.0.0-20181108010431-42b317875d0f \
            golang.org/x/sync@v0.0.0-20180314180146-1d60e4601c6f \
            golang.org/x/sync@v0.0.0-20190227155943-e225da77a7e6 \
            golang.org/x/sys@v0.0.0-20200728102440-3e129f6d46b1 \
            golang.org/x/sys@v0.0.0-20200217220822-9197077df867 \
            golang.org/x/sys@v0.0.0-20180830151530-49385e6e1522 \
            golang.org/x/sys@v0.0.0-20180909124046-d0be0721c37e \
            golang.org/x/sys@v0.0.0-20181029174526-d69651ed3497 \
            golang.org/x/sys@v0.0.0-20190316082340-a2f829d7f35f \
            golang.org/x/sys@v0.0.0-20190412213103-97732733099d \
            golang.org/x/sys@v0.0.0-20190215142949-d0b11bdaac8a \
            golang.org/x/sys@v0.0.0-20220817070843-5a390386f1f2 \
            golang.org/x/text@v0.3.1-0.20180807135948-17ff2d5776d2 \
            golang.org/x/text@v0.3.0 \
            golang.org/x/time@v0.0.0-20181108054448-85acf8d2951c \
            golang.org/x/time@v0.0.0-20180412165947-fbb02b2291d2 \
            golang.org/x/tools@v0.0.0-20181030000716-a0a13e073c7b \
            golang.org/x/tools@v0.0.0-20180828015842-6cd1fcedba52 \
            golang.org/x/tools@v0.0.0-20190114222345-bf090417da8b \
            golang.org/x/tools@v0.0.0-20190226205152-f727befe758c \
            golang.org/x/tools@v0.0.0-20190312151545-0bb0c0a6e846 \
            golang.org/x/tools@v0.0.0-20200117012304-6edc0a871e69 \
            google.golang.org/api@v0.1.0 \
            google.golang.org/api@v0.0.0-20180910000450-7ca32eb868bf \
            google.golang.org/api@v0.0.0-20181030000543-1d582fd0359e \
            google.golang.org/genproto@v0.0.0-20190306203927-b5d61aea6440 \
            google.golang.org/genproto@v0.0.0-20181202183823-bd91e49a0898 \
            google.golang.org/genproto@v0.0.0-20180817151627-c66870c02cf8 \
            google.golang.org/genproto@v0.0.0-20180831171423-11092d34479b \
            google.golang.org/genproto@v0.0.0-20181029155118-b69ba1387ce2 \
            google.golang.org/genproto/googleapis/rpc@v0.0.0-20241202173237-19429a94021a \
            google.golang.org/grpc@v1.14.0 \
            google.golang.org/grpc@v1.16.0 \
            google.golang.org/grpc@v1.17.0 \
            google.golang.org/grpc@v1.19.0 \
            google.golang.org/appengine@v1.1.0 \
            google.golang.org/appengine@v1.2.0 \
            google.golang.org/appengine@v1.3.0 \
            google.golang.org/appengine@v1.4.0 \
            grpc.go4.org@v0.0.0-20170609214715-11d0a25b4919 \
            honnef.co/go/tools@v0.0.0-20190102054323-c2f93a96b099 \
            honnef.co/go/tools@v0.0.0-20190106161140-3f1c8253044a \
            honnef.co/go/tools@v0.0.0-20180728063816-88497007e858 \
            gopkg.in/inf.v0@v0.9.1 \
            gopkg.in/yaml.v1@v1.0.0-20140924161607-9f9df34309c0 \
            gopkg.in/yaml.v2@v2.2.1 \
            gopkg.in/yaml.v2@v2.2.2 \
            gopkg.in/yaml.v3@v3.0.1 \
            sourcegraph.com/sourcegraph/go-diff@v0.5.0 \
            sourcegraph.com/sqs/pbtypes@v0.0.0-20180604144634-d3ebe8f20ae4
          for arch in arm arm64 386 amd64; do
            GOOS=android GOARCH="$arch" CGO_ENABLED=1 \
              go list -deps -test \
                -tags with_conntrack,with_gvisor,with_quic,with_wireguard,with_utls,with_clash_api \
                -f '{{if and .Module .Module.Path .Module.Version}}{{.Module.Path}}@{{.Module.Version}}{{end}}' \
                all \
                | sort -u \
              | while read -r module; do
                case "$module" in
                  ""|github.com/matsuridayo/libneko@*|github.com/sagernet/sing-box@*|golang.org/x/mobile@v0.0.0-00010101000000-000000000000)
                    continue
                    ;;
                esac
                go mod download "$module"
              done
          done
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          cp -R "$TMPDIR/go-mod-cache" "$out"
          runHook postInstall
        '';
      };

      gradle =
        (gradle-packages.mkGradle {
          version = "8.10.2";
          hash = "sha256-McVXE+QCM6gwOCfOtCykikcmegrUurkXcSMSHnFSTCY=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "nekobox-for-android";
      version = "1.4.2";

      src = fetchFromGitHub {
        owner = "MatsuriDayo";
        repo = "NekoBoxForAndroid";
        tag = finalAttrs.version;
        hash = "sha256-vbuqD34NuKxnxfsGaInCm01EEv873i4cctFX3+2EEoA=";
      };

      gradleBuildTask = ":app:assembleFdroidRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      postPatch = ''
        cat > settings.gradle.kts.new <<'EOF'
        pluginManagement {
            repositories {
                google()
                mavenCentral()
                gradlePluginPortal()
                maven(url = "https://jitpack.io")
            }
            resolutionStrategy {
                eachPlugin {
                    if (requested.id.id == "com.android.application" || requested.id.id == "com.android.library") {
                        val agpVersion = requested.version ?: "8.8.1"
                        useModule("com.android.tools.build:gradle:$agpVersion")
                    }
                    if (
                        requested.id.id == "org.jetbrains.kotlin.android" ||
                        requested.id.id == "kotlin-android" ||
                        requested.id.id == "org.jetbrains.kotlin.jvm" ||
                        requested.id.id == "kotlin-parcelize"
                    ) {
                        val kotlinVersion = requested.version ?: "2.0.21"
                        useModule("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
                    }
                    if (requested.id.id == "com.google.devtools.ksp") {
                        val kspVersion = requested.version ?: "2.0.21-1.0.27"
                        useModule("com.google.devtools.ksp:symbol-processing-gradle-plugin:$kspVersion")
                    }
                    if (requested.id.id == "org.gradle.kotlin.kotlin-dsl") {
                        val kotlinDslVersion = requested.version ?: "6.4.2"
                        useModule("org.gradle.kotlin:gradle-kotlin-dsl-plugins:$kotlinDslVersion")
                    }
                }
            }
        }

        EOF
        cat settings.gradle.kts >> settings.gradle.kts.new
        mv settings.gradle.kts.new settings.gradle.kts
        substituteInPlace buildSrc/build.gradle.kts \
          --replace-fail '    `kotlin-dsl`' '    id("org.gradle.kotlin.kotlin-dsl") version "6.4.2"'
        cat >> build.gradle.kts <<'EOF'
        tasks.register("lintVitalRelease")
        EOF
      '';

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./nekobox-for-android_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21
        go_1_25
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.1/aapt2";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      preBuild = ''
        export HOME="$PWD/.home"
        mkdir -p "$HOME/.android" "$HOME/.cache"

        export GOCACHE="$TMPDIR/go-cache"
        export GOPATH="$TMPDIR/go"
        export GOMODCACHE="$PWD/.gomodcache"
        export GOWORK=off
        cp -R ${libcoreGoModCache} "$GOMODCACHE"
        chmod -R u+w "$GOMODCACHE"
        export GOPROXY=off
        export GOSUMDB=off
        export GOFLAGS=-mod=mod
        export PATH="$GOPATH/bin:${go_1_25}/bin:$PATH"
        export CGO_ENABLED=1
        export GO386=softfloat

        cp -R ${xMobileSrc} x-mobile
        chmod -R u+w x-mobile
        (
          cd x-mobile
          patch -p1 < ${../tailscale/gomobile-avoid-empty-go-mod.patch}
          substituteInPlace cmd/gomobile/init.go \
            --replace-fail 'if err := goInstall([]string{"golang.org/x/mobile/cmd/gobind@latest"}, nil); err != nil {' \
                           'if _, err := exec.LookPath("gobind"); err != nil {'
          substituteInPlace cmd/gomobile/bind_androidapp.go \
            --replace-fail 'if err := goModTidyAt(srcDir, env); err != nil {' 'if false {'
          substituteInPlace cmd/gomobile/build.go \
            --replace-fail 'if gmc, err := goModCachePath(); err == nil {' 'if false {' \
            --replace-fail 'env = append([]string{"GOMODCACHE=" + gmc}, env...)' 'env = append([]string{}, env...)'
          go mod edit \
            -require=golang.org/x/mod@v0.27.0 \
            -require=golang.org/x/sync@v0.16.0 \
            -require=golang.org/x/tools@v0.36.0 \
            -require=golang.org/x/sys@v0.35.0 \
            -require=golang.org/x/image@v0.25.0
          go get ./cmd/gomobile ./cmd/gobind
          go install ./cmd/gomobile ./cmd/gobind
        )

        cp -R ${singBoxSrc} sing-box
        cp -R ${libnekoSrc} libneko
        substituteInPlace libcore/go.mod \
          --replace-fail '../../libneko' '../libneko' \
          --replace-fail '../../sing-box' '../sing-box' \
          --replace-fail 'golang.org/x/mobile v0.0.0-20231108233038-35478a0c49da' 'golang.org/x/mobile v0.0.0-00010101000000-000000000000'
        (
          cd libcore
          go mod edit -replace=golang.org/x/mobile=../x-mobile
          go mod vendor
        )

        mkdir -p app/libs
        (
          cd libcore
          gomobileBin="$PWD/../gomobile-bin"
          gobindBin="$PWD/../gobind-bin"
          (cd ../x-mobile && go build -o "$gomobileBin" ./cmd/gomobile)
          (cd ../x-mobile && go build -o "$gobindBin" ./cmd/gobind)
          mkdir -p "$GOPATH/bin" "$GOPATH/pkg/gomobile" "$GOPATH/src/golang.org/x"
          install -m755 "$gobindBin" "$GOPATH/bin/gobind"
          ln -s "$PWD/../x-mobile" "$GOPATH/src/golang.org/x/mobile"
          rm -rf vendor/golang.org/x/mobile
          cp -R vendor/. "$GOPATH/src/"
          find "$GOMODCACHE" -name go.mod -print | while read -r gomod; do
            module_dir="$(dirname "$gomod")"
            rel_path="''${module_dir#$GOMODCACHE/}"
            module_path="''${rel_path%@*}"
            mkdir -p "$GOPATH/src/$(dirname "$module_path")"
            if [ ! -e "$GOPATH/src/$module_path" ]; then
              ln -s "$module_dir" "$GOPATH/src/$module_path"
            fi
          done
          export PATH="$GOPATH/bin:$PATH"
          "$gomobileBin" bind -v \
            -androidapi 21 \
            -trimpath \
            -ldflags='-s -w' \
            -tags='with_conntrack,with_gvisor,with_quic,with_wireguard,with_utls,with_clash_api' \
            .
          cp -f libcore.aar ../app/libs/libcore.aar
        )
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.1/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.1/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_dir="app/build/outputs/apk/fdroid/release"
        apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apk_dir/output-metadata.json" | head -n 1)"
        test -n "$apk_name"
        apk_path="$apk_dir/$apk_name"
        test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/nekobox-for-android.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "NekoBox for Android (fdroid flavor, unsigned)";
        homepage = "https://github.com/MatsuriDayo/NekoBoxForAndroid";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "nekobox-for-android.apk";
  signScriptName = "sign-nekobox-for-android";
  fdroid = {
    appId = "moe.nb4a";
    metadataYml = ''
      Categories:
        - Internet
      License: GPL-3.0-only
      SourceCode: https://github.com/MatsuriDayo/NekoBoxForAndroid
      IssueTracker: https://github.com/MatsuriDayo/NekoBoxForAndroid/issues
      Changelog: https://github.com/MatsuriDayo/NekoBoxForAndroid/releases
      AutoName: NekoBox
      Summary: Universal proxy client using sing-box
      Description: |-
        NekoBox is an Android proxy client built on sing-box.
        This package builds the upstream fdroid flavor from source.
    '';
  };
}
