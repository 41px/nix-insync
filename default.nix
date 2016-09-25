{ stdenv, fetchurl, dpkg, makeWrapper, python, zlib, file, openssl, fontconfig, expat, glib, gtk3 }:

let
   url = "http://s.insynchq.com/builds/insync_1.3.11.36106-wheezy_amd64.deb";
   sha256 = "1wqkfddxi9qgmgcifj54ajbdq5w6a54ba65hb5fwnq0yw1hijfzb";
in stdenv.mkDerivation {
    name = "insync";
    buildInputs = [ dpkg makeWrapper file ];
    src = fetchurl {
      url = "http://s.insynchq.com/builds/insync_1.3.11.36106-wheezy_amd64.deb";
      sha256 =  "1wqkfddxi9qgmgcifj54ajbdq5w6a54ba65hb5fwnq0yw1hijfzb";
    };
    libPath = stdenv.lib.makeLibraryPath [ python zlib openssl fontconfig expat glib gtk3 ];
    unpackPhase = "true";    
    buildCommand = ''
mkdir -p $out/bin
dpkg -x $src $out

substituteInPlace $out/usr/bin/insync --replace /bin/bash $(type -P bash)
substituteInPlace $out/usr/bin/insync --replace /usr/lib/insync $out/usr/lib/insync

cp $out/usr/bin/insync $out/bin/

for exec in $(find $out -executable)
do
    if [ $(file $exec | grep "ELF" | awk '{ print $1 }' | sed 's/://g') ]; then
        echo "patch $exec"
        patchelf --interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" --set-rpath "$out/usr/lib/insync:$libPath" $exec
    fi
done

for libname in `find "$out" -name '*.so'`
do
    echo "patch $libname"
    # patchelf --shrink-rpath "$out/usr/lib/insync:$libname"
    patchelf --set-rpath "$out/usr/lib/insync:$libPath" $libname
done

for libname in `find "$out" -name '*.so.*'`
do
    echo "patch $libname"
    # patchelf --shrink-rpath "$out/usr/lib/insync:$libname"
    patchelf --set-rpath "$out/usr/lib/insync:$libPath" $libname
done

fixupPhase

'';

}
