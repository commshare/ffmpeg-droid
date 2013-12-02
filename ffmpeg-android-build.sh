#!/bin/bash

FFMPEG_SOURCE="git://source.ffmpeg.org/ffmpeg.git"
FFMPEG_VERSION=`cat version`

[ -z "$NDK_HOME" ] && NDK_HOME=/opt/android-ndk

# defaults
api_level=14
target=armeabi-v7a
compiler_version=4.8
ndk_home=$NDK_HOME
build_forks=

usage() {
cat << _EOF
Use: $0 [--api-level LEVEL] [--target TARGET] [--compiler-version CVER] [--ndk-home NDK_HOME] [-j BUILD_FORKS]
  
  LEVEL: see at the NDK_HOME/platform. Level is a digit
    14*
  
  TARGET: 
     armeabi
     armeabi-v7a*
     mips
     x86

  CVER:
    4.6
    4.8*

  NDK_HOME: usaly /opt/android-ndk (this value sets by defaul)

  BUILD_FORKS: amout of parallel build processes, autodetect if omited

  Asterisk (*) marks default values
_EOF
}

# parse command line
while [ -n "$1" ]; do
    cur=$1
    
    case "$cur" in
        --api-level)
            shift
            api_level=$1
        ;;
        
        --target)
            shift
            target=$1
        ;;
        
        --compiler-version)
            shift
            compiler-version=$1
        ;;
        
        --ndk-home)
            shift
            ndk_home=$1
        ;;
        
        -j)
            shift
            build_forks=$1
        ;;
        
        --help)
            usage
            exit 0
        ;;
        
        *)
            echo "Unknown option: $1"
            exit 1
        ;;
    esac
    
    shift
done

# Autodetect parallel build
if [ -z "$build_forks" ]; then
    build_forks=`cat /proc/cpuinfo | grep processor | wc -l`
fi

# Android NDK setup
NDK_PLATFORM_LEVEL=$api_level
NDK_COMPILER_VERSION=$compiler_version
NDK_UNAME=`uname -s | tr '[A-Z]' '[a-z]'`

setup_abi() {
    
    
    if [ $NDK_ABI = "x86" ]; then
        HOST=i686-linux-android
        NDK_TOOLCHAIN=$NDK_ABI-$NDK_COMPILER_VERSION
    else
        HOST=$NDK_ABI-linux-androideabi
        NDK_TOOLCHAIN=$HOST-$NDK_COMPILER_VERSION
    fi

}

# select ABI
case $target in
    armeabi)
        NDK_ABI=arm
        HOST=$NDK_ABI-linux-androideabi
        NDK_TOOLCHAIN=$HOST-$NDK_COMPILER_VERSION

        FFMPEG_ARCH="arm"
        FFMPEG_FLAGS_EXTRA=""

        CFLAGS="-O3 -Wall -mthumb -pipe -fpic -fasm \
            -finline-limit=300 -ffast-math \
            -fstrict-aliasing -Werror=strict-aliasing \
            -fmodulo-sched -fmodulo-sched-allow-regmoves \
            -Wno-psabi -Wa,--noexecstack \
            -D__ARM_ARCH_5__ -D__ARM_ARCH_5E__ \
            -D__ARM_ARCH_5T__ -D__ARM_ARCH_5TE__ \
            -DANDROID -DNDEBUG"

        EXTRA_CFLAGS="-march=armv6"
        EXTRA_LDFLAGS=""

    ;;
    armeabi-v7a)
        NDK_ABI=arm
        HOST=$NDK_ABI-linux-androideabi
        NDK_TOOLCHAIN=$HOST-$NDK_COMPILER_VERSION

        FFMPEG_ARCH="arm"
        FFMPEG_FLAGS_EXTRA="--cpu=cortex-a8"

        CFLAGS="-O3 -Wall -mthumb -pipe -fpic -fasm \
            -finline-limit=300 -ffast-math \
            -fstrict-aliasing -Werror=strict-aliasing \
            -fmodulo-sched -fmodulo-sched-allow-regmoves \
            -Wno-psabi -Wa,--noexecstack \
            -D__ARM_ARCH_5__ -D__ARM_ARCH_5E__ \
            -D__ARM_ARCH_5T__ -D__ARM_ARCH_5TE__ \
            -DANDROID -DNDEBUG"

        EXTRA_CFLAGS="-march=armv7-a -mfpu=neon -mfloat-abi=softfp -mvectorize-with-neon-quad"
        EXTRA_LDFLAGS="-Wl,--fix-cortex-a8"

    ;;
    x86)
        NDK_ABI=x86
        HOST=i686-linux-android
        NDK_TOOLCHAIN=$NDK_ABI-$NDK_COMPILER_VERSION
        
        FFMPEG_ARCH="x86"
        FFMPEG_FLAGS_EXTRA=""
        
        CFLAGS="-O3 -Wall -mthumb -pipe -fpic -fasm \
            -finline-limit=300 -ffast-math \
            -fstrict-aliasing -Werror=strict-aliasing \
            -fmodulo-sched -fmodulo-sched-allow-regmoves \
            -Wno-psabi -Wa,--noexecstack \
            -DANDROID -DNDEBUG"

        EXTRA_CFLAGS="-march=i686 -mtune=atom -mstackrealign -msse3 -mfpmath=sse -m32"
        EXTRA_LDFLAGS=""

    ;;
    mips)
        NDK_ABI=mips
        HOST=mipsel-linux-android
        NDK_TOOLCHAIN=$HOST-$NDK_COMPILER_VERSION

        FFMPEG_ARCH="mips"
        FFMPEG_FLAGS_EXTRA=""

        CFLAGS="-O3 -Wall -mthumb -pipe -fpic -fasm \
            -finline-limit=300 -ffast-math \
            -fstrict-aliasing -Werror=strict-aliasing \
            -fmodulo-sched -fmodulo-sched-allow-regmoves \
            -Wno-psabi -Wa,--noexecstack \
            -DANDROID -DNDEBUG"

        EXTRA_CFLAGS="-march=mipsel"
        EXTRA_LDFLAGS=""

    ;;
    *)
        echo "Unsupported target: $target"
        exit 1
    ;;
esac

NDK_TARGET=$target
NDK_SYSROOT=$NDK_HOME/platforms/android-$NDK_PLATFORM_LEVEL/arch-$NDK_ABI

export TOOLCHAIN=`pwd`/ffmpeg-git/ffmpeg-android-$NDK_TARGET
export SYSROOT=$TOOLCHAIN/sysroot
export PATH=$TOOLCHAIN/bin:$PATH

export CC=$HOST-gcc
export CXX=$HOST-g++
export LD=$HOST-ld
export AR=$HOST-ar


FFMPEG_FLAGS="\
  --prefix=$TOOLCHAIN/build \
  --target-os=linux \
  --arch=$FFMPEG_ARCH \
  $FFMPEG_FLAGS_EXTRA \
  --enable-runtime-cpudetect \
  --enable-pic \
  --enable-cross-compile \
  --cross-prefix=$HOST- \
  --enable-gpl \
  --enable-shared \
  --disable-symver \
  --disable-doc \
  --disable-ffplay \
  --disable-ffmpeg \
  --disable-ffprobe \
  --disable-ffserver \
  --enable-avdevice \
  --enable-avfilter \
  --enable-encoders  \
  --enable-muxers \
  --enable-protocols  \
  --enable-parsers \
  --enable-demuxers \
  --disable-demuxer=sbg \
  --enable-decoders \
  --enable-bsfs \
  --enable-network \
  --enable-swscale  \
  --enable-asm \
  --enable-version3"

START_DIR=`pwd`

echo "Build for $HOST"

get_source() {
    if [ -x "ffmpeg-git" ]; then
        cd ffmpeg-git

        branch=`git branch | grep '^\*' | awk '{print $2}'`

        if [ "$branch" != "master" ]; then
            echo "Clean up previous build: $branch"

            # Revert all changes
            git checkout .
            git reset
            git clean -f -x -d

            git checkout master
            git branch -D "$branch"
        fi

        git pull origin master
    else
        git clone $FFMPEG_SOURCE ffmpeg-git
        cd ffmpeg-git
    fi

    branch="android-build-$NDK_TARGET"
    git branch -d $branch || git branch -D $branch > /dev/null 2>&1
    git checkout -b android-build-$NDK_TARGET $FFMPEG_VERSION
}

prepare_ndk() {
    set -x
    rm -rf /tmp/ndk-$USER
    $NDK_HOME/build/tools/make-standalone-toolchain.sh \
        --toolchain=$NDK_TOOLCHAIN \
        --platform=android-$NDK_PLATFORM_LEVEL \
        --install-dir=$TOOLCHAIN
}

configure_ffmpeg() {
    ./configure $FFMPEG_FLAGS --extra-cflags="$CFLAGS $EXTRA_CFLAGS" --extra-ldflags="$EXTRA_LDFLAGS"
}

build_ffmpeg() {
    make clean
    make -j $build_forks
    make install

    mkdir -p "$START_DIR/targets/$NDK_TARGET"
    cp -a "$TOOLCHAIN/build/"* "$START_DIR/targets/$NDK_TARGET/"
    rm -rf "$START_DIR/targets/$NDK_TARGET/lib/pkgconfig"
}

post_build_ffmpeg() {
    rm libavcodec/inverse.o
    $CC -lm -lz -shared --sysroot=$SYSROOT \
        -Wl,--no-undefined -Wl,-z,noexecstack $EXTRA_LDFLAGS \
            libavutil/*.o libavutil/arm/*.o libavcodec/*.o libavcodec/arm/*.o \
            libavformat/*.o libswresample/*.o libswscale/*.o -o libffmpeg.so
    $HOST-strip --strip-unneeded libffmpeg.so
}

get_source || exit 1
prepare_ndk || exit 2
configure_ffmpeg || exit 3
build_ffmpeg || exit 4
#post_build_ffmpeg
