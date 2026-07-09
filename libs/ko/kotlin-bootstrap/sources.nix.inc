{ fetchFromGitHub }:
let
  kotlinSrc = version: hash: fetchFromGitHub {
    owner = "JetBrains";
    repo = "kotlin";
    tag = "build-${version}";
    inherit hash;
  };
  intellijSrc = revOrTag: hash:
    if (builtins.match "[0-9]+" revOrTag) != null then
      fetchFromGitHub {
        owner = "JetBrains";
        repo = "intellij-community";
        tag = revOrTag;
        inherit hash;
      }
    else
      fetchFromGitHub {
        owner = "JetBrains";
        repo = "intellij-community";
        rev = revOrTag;
        inherit hash;
      };
in
{
  kotlin-bootstrap = fetchFromGitHub {
    owner = "ebourg";
    repo = "kotlin-bootstrapping";
    rev = "2328eb7785d0f5537f2888e6813d81e85ca0eac5";
    hash = "sha256-Zu3RDBztCIEg1Jp7CnH7k/Rt89MkbCoG5TCp/6FTYVY=";
  };

  intellij-133 = fetchFromGitHub {
    owner = "JetBrains";
    repo = "intellij-community";
    rev = "bc220ce6434e2fb0b0515e068b2c570b9a3a055e";
    hash = "sha256-9Vr0/PJ+OA+dGB0fj2LJT0voFNE1Fw6P+nj425APi0w=";
  };

  intellij-134 = intellijSrc "1168c7b8cb4dc8318b8d24037b372141730a0d1f" "sha256-aa3AWnZOMB4nf5STjk9oyQFK4SiNNW0SL3b3SXCNuOc=";
  intellij-135 = intellijSrc "135" "sha256-qgAxjSbseEGQiiGW3Sf8dEmHdmWF7mqlzWN8ah2mp7c=";
  intellij-138 = intellijSrc "070c64f86da3bfd3c86f151c75aefeb4f67870c8" "sha256-4+KHVA7rFMqp5f519D5PX1+9pPL61dUnJK5ksZP+6gE=";
  intellij-139 = intellijSrc "26e72feacf91bfb222bec00b3139ed05aa3084b5" "sha256-TsdwIrXQvO8xDPQ1Hk2KhCBbd29FqFa9prOztkUVAVc=";
  intellij-141 = intellijSrc "141" "sha256-9rRoWxELfusNsnPefV5hPrpw2ZBypCFNjtEAezQZur4=";
  intellij-143 = intellijSrc "143" "sha256-xZiKwE9UHXS9Wy75nK4XqkL3FlxwIsQe/DFchISXQdQ=";

  # Kotlin versions
  k0_6_786   = kotlinSrc "0.6.786"   "sha256-EeMavn930d/i/sjutW6i1CRaZS+mNw/CkqfZdO/N8kU=";
  k0_6_1364  = kotlinSrc "0.6.1364"  "sha256-JbjnkxQvggnRc21hV62pu1GcusVEMBPBZ9UY5FjB5fc=";
  k0_6_1932  = kotlinSrc "0.6.1932"  "sha256-Nw7Cgv5iKu1a2slse6Q5fn8EhNrZpOnZpPPMojjWN+Q=";
  k0_6_2107  = kotlinSrc "0.6.2107"  "sha256-IVdkqIOCKn5e1TQAN7Knl7SIG/Y7SJFKRVmD9nvJ4bE=";
  k0_6_2338  = kotlinSrc "0.6.2338"  "sha256-DBEKuJc9m7lbdwDI1JvABMToEnnO49x/5BFUxHv4Zpk=";
  k0_6_2451  = kotlinSrc "0.6.2451"  "sha256-ijpEoxy4E36SSS/VjeEJR4F1sdx9UBHVaTlC17o9E8Y=";
  k0_6_2516  = kotlinSrc "0.6.2516"  "sha256-JcPNh/hykJ+IwMb+AyOInx7OBfzHDvfk6e7c/wSKHd4=";
  k0_7_333   = kotlinSrc "0.7.333"   "sha256-Unywqx6lfOxqizcH/AKa6AzqwPsKfud8h7guWgwnvQs=";
  k0_7_638   = kotlinSrc "0.7.638"   "sha256-EfS3PXq6HjrZ7CisKttJY1waNwh+d4jGWIQgLfhgEqw=";
  k0_7_1214  = kotlinSrc "0.7.1214"  "sha256-Dx1z+wVOYKqxtZbOe1ewkkqQYZRkGQXoslQuWIORQUQ=";
  k0_8_84    = kotlinSrc "0.8.84"    "sha256-Uuqq8+m58OI7BVE6VssrcSXfZDaTZyTdQg38laTdrS4=";
  k0_8_409   = kotlinSrc "0.8.409"   "sha256-AU1kRuulW741ec9T5W8HDKxadcxxQE+qDeYgww2N/dE=";
  k0_8_418   = kotlinSrc "0.8.418"   "sha256-ydpNBeWLaURPWjQQKehZTKFbeTgscO2PoZBnp1WiyD0=";
  k0_8_422   = kotlinSrc "0.8.422"   "sha256-6OCUw+9qEogxKZiqUZHSL/Vricqnx3KBLp6SkjW8Mjc=";
  k0_8_1444  = kotlinSrc "0.8.1444"  "sha256-N1dE48bHtZE4dyIiN8RsDE8MkGboy0EF9vS9BFISCyI=";
  k0_9_21    = kotlinSrc "0.9.21"    "sha256-GDPhaRsH2saq1hJSTEbU5zlqwYeo+9UktaEBOwt8WP8=";
  k0_9_738   = kotlinSrc "0.9.738"   "sha256-bsK2hm4t7eE4V4smr2QTQOzGnplBo9LUOGcbSn4Jh2A=";
  k0_9_1204  = kotlinSrc "0.9.1204"  "sha256-RwFTgQlPwkItRYORWb/q3qly+7NUl9spV2gs5NYTR0c=";
  k0_10_300  = kotlinSrc "0.10.300"  "sha256-hCtMdfeUbKN6EcLrY8ugczMsJY8KJyeLC5cOqU9SbL0=";
  k0_10_823  = kotlinSrc "0.10.823"  "sha256-HPOohk4aPZ6HKtRctPhysAQu8Ds687rxHiM7i8QAwKA=";
  k0_10_1023 = kotlinSrc "0.10.1023" "sha256-mXQ2GM9ZknGBoLrGyMCxFOdAcAW5r47wyZsYblqIRsI=";
  k0_10_1336 = kotlinSrc "0.10.1336" "sha256-h1DC/8ao1PWylaQd3rOLJXO6/Chv7PXrX4+kbS/jzF0=";
  k0_10_1426 = kotlinSrc "0.10.1426" "sha256-9I5v0bvgsbVIL2GIQtdomvsDFp+8W2ASx1Sz6FivdPo=";
  k0_11_153  = kotlinSrc "0.11.153"  "sha256-19un1FQC5Kj4JVhzfeOsA+HuSCK8HjICFrZTzOb50dk=";
  k0_11_873  = kotlinSrc "0.11.873"  "sha256-3IflJIszTOpht9ficIXNCnIJWDfMRaUX434nBiLYqU8=";
  k0_11_992  = kotlinSrc "0.11.992"  "sha256-XkkVDTy8gzixy52D3KAC13BJsxpe/APCsNln7niUi0Y=";
  k0_11_1014 = kotlinSrc "0.11.1014" "sha256-4wLoq4Z1Z7MejSU4uowgyWtMdYEP3UkUYWljNJ4N7CQ=";
  k0_11_1201 = kotlinSrc "0.11.1201" "sha256-2/akqXXB3qnQgJP+xJeO3c5eBkMuFOI0MZAkSauWCAI=";
  k0_11_1393 = kotlinSrc "0.11.1393" "sha256-kGWTUbFFU5t/aPhCDPJPJWHZ3BzkU9sIoIKxSmYpnSs=";
  k0_12_108  = kotlinSrc "0.12.108"  "sha256-fw7K1lsenWkEtwgrT8+Nk0zB60G3SMn/+Ih/qWita38=";
  k0_12_115  = kotlinSrc "0.12.115"  "sha256-7wBoOmBuXnXBHXrOHk/GLtxl0wZCiIcqelfi2c3iDcw=";
  k0_12_176  = kotlinSrc "0.12.176"  "sha256-IUXsT6BMnOzLzcnJHF7/pEJ6shptGND2pUQmcc5bpww=";
  k0_12_470  = kotlinSrc "0.12.470"  "sha256-AnH2BeZfZF0mymLwjwGAbZc1olSpp/4d0RvjQ6V/i8Y=";
  k0_12_1077 = kotlinSrc "0.12.1077" "sha256-8jSnhKs5cGFFYobCtxLOLfH0/btaFBn9+3dk9MTo9Bk=";
  k0_12_1250 = kotlinSrc "0.12.1250" "sha256-EUc2WfzowwTtIcU1FNym9ThYNt9ETODVbo5GCAOmAWc=";
  k0_12_1306 = kotlinSrc "0.12.1306" "sha256-nBs45p103ZPFTuINIYWoFljeNcaD8jsZoJGGu7dfSBM=";
  k0_13_177  = kotlinSrc "0.13.177"  "sha256-XzgSkJGHvAEUYDBJc6Pxs8Jtcl5CLVwUSyRg1XGp8N8=";
  k0_13_791  = kotlinSrc "0.13.791"  "sha256-4TRVnUGtwftEu/eY7/Z84GrL2OgTfasQnUGutd/jnvg=";
  k0_13_899  = kotlinSrc "0.13.899"  "sha256-nGmOF+r85p/uON/XDtI23DyMq4XsMX2yxj1+i77eooM=";
  k0_13_1118 = kotlinSrc "0.13.1118" "sha256-MCuOAuSCVsVBiZzXo5ZBiK+5e9wSKXsFEZMn/1D1A2A=";
  k0_13_1304 = kotlinSrc "0.13.1304" "sha256-Z+jqnkDDoKXi0OFAmYNVBWoqDTYzNj5wcWquGjFh45Y=";
  k0_14_209  = kotlinSrc "0.14.209"  "sha256-2ARuWOk/W3yK+HamIBWAYeqp3XBg2cUxPoWH1YEaI7k=";
  k0_14_398  = kotlinSrc "0.14.398"  "sha256-I4c1L2UgLGg78QhkjsV33RaGuwNAy4pzKL0RHKbVUrI=";
  k0_15_8    = kotlinSrc "0.15.8"    "sha256-MC7Oi9y17pqcS0H4xO8voP8QCYrnSGP44xrV95s59u4=";
  k0_15_394  = kotlinSrc "0.15.394"  "sha256-9XEhGfBKUl8Go3Wb48H2v6ARdmVjkaCh4EMCFtjBm50=";
  k0_15_541  = kotlinSrc "0.15.541"  "sha256-s4XlcKYUJuCnNDMzczVULkVtjCycR9lRkTuZ9eJ99ms=";
  k0_15_604  = kotlinSrc "0.15.604"  "sha256-jJo85h91wxASrtEVIJYdNtbYx/FE996JRZkBJt7rObM=";
  k0_15_723  = kotlinSrc "0.15.723"  "sha256-tnk5tG+MStMvaQnQEG2U8o1cXBR2ok/CmucP/OnW2cE=";
  k1_0_0_beta_2055 = kotlinSrc "1.0.0-beta-2055" "sha256-cKN4uOm/Fuzg18jH0xo68baEPc5AQmP+rMzvqmInChE=";
  k1_0_0_beta_3070 = kotlinSrc "1.0.0-beta-3070" "sha256-8CV0Jiu5FfFeWAfi1a00fCSh0UgkPx0H8NHP4NRDkmE=";
  k1_0_0_beta_4091 = kotlinSrc "1.0.0-beta-4091" "sha256-+E5jyQrMuo4URsexn+2pzxvCK0NntzBE3dentsGVh6Y=";
  k1_0_0_beta_5010 = kotlinSrc "1.0.0-beta-5010" "sha256-F9UElpb26ZEiJ4ytcauZeEZx4WS2BNhTCwsKrFEgJzE=";
  k1_0_0_beta_5604 = kotlinSrc "1.0.0-beta-5604" "sha256-F+ynbCtPy6UDlfI/EPs9p79hBv38eJ1kY7qNjNACl6E=";
  k1_0_0_dev_162   = kotlinSrc "1.0.0-dev-162"   "sha256-7zFshz2b4keo3BrYHUAlmqB27HjaCOaL9wyHZknY7tQ=";
  k1_0_0           = kotlinSrc "1.0.0"           "sha256-az4maYaBFJFvQ6ik6/qdu840yz3TBPG5nAFNM5sUI3I=";
}
