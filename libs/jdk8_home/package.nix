{ jdk8, stdenv }: if stdenv.isDarwin then jdk8 else "${jdk8}/lib/openjdk"
