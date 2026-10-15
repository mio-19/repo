{ fetchFromGitHub, okio_common }:
okio_common {
  version = "1.17.4";
  src = fetchFromGitHub {
    owner = "square";
    repo = "okio";
    tag = "okio-parent-1.17.4";
    hash = "sha256-iofH62RrGOJ5i6GXEPWgfPZZZ/6ZrqCQzn49jR4kuDg=";
  };
  pomHash = "sha256-IK30Thh7VXt2Bab4sbqCuljg1Hl7w5f2oOBeTtlUlcY=";
}
