#!/bin/sh

set -xe

VERSION="0.1.3"                                                           #

SDKVERSION="7.0"

CURRENTPATH=`pwd`

mkdir -p "${CURRENTPATH}/src"
tar zxf opencore-amr-${VERSION}.tar.gz -C "${CURRENTPATH}/src"
cd "${CURRENTPATH}/src/opencore-amr-${VERSION}"

DEVELOPER=`xcode-select -print-path`
DEST="${CURRENTPATH}/opencore-amr-iphone"
mkdir -p "${DEST}"

ARCHS="x86_64 arm64"  #armv7 armv7s
LIBS="libopencore-amrnb.a libopencore-amrwb.a"

./configure

for arch in $ARCHS; do
    make clean
    IOSMV=" -miphoneos-version-min=7.0"
    case $arch in
    arm*)
        if [ $arch == "arm64" ]
        then
            IOSMV=" -miphoneos-version-min=7.0"
        fi
        echo "Building opencore-amr for iPhoneOS $arch ****************"
        PATH=`xcodebuild -version -sdk iphoneos PlatformPath`"/Developer/usr/bin:$PATH" \
        SDK=`xcodebuild -version -sdk iphoneos Path` \
        CXX="xcrun --sdk iphoneos clang++ -arch $arch $IOSMV --sysroot=$SDK -isystem $SDK/usr/include  -fembed-bitcode" \
        LDFLAGS="-Wl" \
        ./configure \
        --host=arm-apple-darwin \
        --prefix=$DEST \
        --disable-shared
        ;;
    *)
        echo "Building opencore-amr for iPhoneSimulator $arch *****************"
        PATH=`xcodebuild -version -sdk iphonesimulator PlatformPath`"/Developer/usr/bin:$PATH" \
        CXX="xcrun --sdk iphonesimulator clang++ -arch $arch $IOSMV  -fembed-bitcode" \
        ./configure \
        --host=$arch \
        --prefix=$DEST \
        --disable-shared
        ;;
    esac
    make -j3
    make install
    for i in $LIBS; do
        mv $DEST/lib/$i $DEST/lib/$i.$arch
    done
done

echo "Merge into universal binary."

for i in $LIBS; do
input=""
for arch in $ARCHS; do
input="$input $DEST/lib/$i.$arch"
done
lipo -create -output $DEST/lib/$i $input
done
