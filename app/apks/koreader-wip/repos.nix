{ fetchgit }:
[
  (fetchgit {
    url = "https://github.com/koreader/libk2pdfopt.git";
    rev = "59ced371378312d8f332d9a35f5b4a3c33b18954";
    hash = "sha256-sG6Rk3XGTgkQjjQZKL/wwB4hLmeLuBu5eby3oIWbFTA=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/lunarmodules/luafilesystem";
    tag = "v1_9_0";
    hash = "sha256-aabznj5k6TMx153VeDBFedv7tFZzvgOkwo4yIEPy0t8=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/famzah/popen-noshell.git";
    rev = "e715396a4951ee91c40a98d2824a130f158268bb";
    hash = "sha256-oIAL6fMw6UfjG2CnV5zK1cZIkCdt68hEbq45dTRpSEM=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/lvandeve/lodepng.git";
    rev = "0b1d9ccfc2093e5d6620cd9a11d03ee6ff6705f5";
    hash = "sha256-wskSBmAB/jT+t+ArGtLghSbdUAty9gbon8wMnpIeiYU=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/libjpeg-turbo/libjpeg-turbo.git";
    tag = "3.1.3";
    hash = "sha256-sMzOyXmq4Oif7Hk+D8GzkQoBBlLp4tz1t7jwR63D4SY=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/lunarmodules/luasocket";
    rev = "e3ca4a767a68d127df548d82669aba3689bd84f4";
    hash = "sha256-AFvenlnmxiVwazb8B29WvPOXyS/VUHze8WDJdsE+m74=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/koreader/lj-wpaclient.git";
    rev = "0d5c8ee336b699dbb35850a7336d24e89e1aac24";
    hash = "sha256-m50+7D+LWl5LTqJttNUrHZnQM1FFXS9RbLglOuR9EQQ=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/notmarek/openlipclua.git";
    rev = "96c2d16696a482664b4e84eb3b6d851f807a44d1";
    hash = "sha256-tklvAJ7Fj/FUX1uIAu4kMDSIXD9tEsAyX49YwxpRwx0=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/NiLuJe/lua-rapidjson";
    rev = "e84973356255bde06a70ce6263a3a0ef5c8f4ad4";
    hash = "sha256-xsbf8AYTmGcKgNefFdQJ197aj9Z7BHvAYVgbjhAMfJ0=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/koreader/KoboUSBMS.git";
    rev = "a35a8f639699deaae2e2ee446b5f6c2d2096c1bb";
    hash = "sha256-tdeVdtu8gjzxUnx4607oR22Fabih13m0X77YZTRFOJg=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/NiLuJe/zsync2.git";
    rev = "e281e1eb4466ff6b3866c25dbe62a3e150fa5bfd";
    hash = "sha256-b+dtLRmQh1FGCjKONZrEeXgXK3itcdM41n7b86nPmMY=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/sammycage/lunasvg.git";
    tag = "v2.3.9";
    hash = "sha256-2kTGIkrcPsAcrCvUtUzUcgpqtCuCuLzs2Z0ImAlq00Y=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://gitlab.com/koreader/djvulibre.git";
    rev = "6a1e5ba1c9ef81c205a4b270c3f121a1e106f4fc";
    hash = "sha256-0YHiKLO5eqD1rGsF4MwaP4IQwdyz31qFyC70SiGxgW8=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/LuaJIT/LuaJIT";
    rev = "659a61693aa3b87661864ad0f12eee14c865cd7f";
    hash = "sha256-5Si9m9nmqVuKdQ9A3iRJlrzWKJHEF0UZYk/hSS71CLM=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/msva/lua-htmlparser";
    rev = "5ce9a775a345cf458c0388d7288e246bb1b82bff";
    hash = "sha256-kMhS7uUVeYRYrJU7VsbRH0aC54F/jaVWh7pdelLmasQ=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/brunoos/luasec";
    tag = "v1.3.2";
    hash = "sha256-sZu6acBs3Gy1h74sK7wU2NvPOd3kDaqeIeBKJ/pJv/E=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/koreader/ffi-cdecl.git";
    rev = "ea45fb34782a29738334e250e820c825d75e5087";
    hash = "sha256-voN75q0JFo0578DpFYpPpNTjSitNGSA63y1wCfrDqBg=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/NiLuJe/FBInk.git";
    rev = "92e127008145b2a22fba7c59815d810d716310dd";
    hash = "sha256-hjOKl/Pa729WoWOASM6sxhU4X/maw5xRxiMXNHeequ8=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/harningt/luajson.git";
    rev = "6ecaf9bea8b121a9ffca5a470a2080298557b55d";
    hash = "sha256-b94hO3BSAyftC3kaEfMxdKpTlpQjO6CqijcQf4kzqls=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/nmoinvaz/minizip";
    rev = "0b46a2b4ca317b80bc53594688883f7188ac4d08";
    hash = "sha256-0ARFhLNex3nUJX9PIp1KxL/VY7DTbOedUkKEupCF1Uw=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/memononen/nanosvg.git";
    rev = "ea6a6aca009422bba0dbad4c80df6e6ba0c82183";
    hash = "sha256-zop4QF6gawQjjsVPb9xqfMqUSawACR6/qjArT1Noqu4=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://framagit.org/fperrad/lua-Spore";
    tag = "0.4.2";
    hash = "sha256-wjXF7oEpdcpt8jmCH2bVj6PijOQpkHJu+22+MS/AbYo=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
  (fetchgit {
    url = "https://github.com/kernelsauce/turbo";
    tag = "v2.1.3";
    hash = "sha256-4QbgBs/sUlaQ/SBQMUm/yvWnrjEUR1tQf1CHW8POO2g=";
    leaveDotGit = true;
    fetchSubmodules = true;
  })
]
