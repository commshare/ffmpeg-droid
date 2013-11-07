Android FFMPEG build script
===========================

Helper script to build FFMPEG for android devices.


Building
--------

For help run
  ./ffmpeg-android-build.sh --help

Use: ./ffmpeg-android-build.sh [--api-level LEVEL] [--target TARGET] [--compiler-version CVER] [--ndk-home NDK_HOME]

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

  NDK_HOME: usaly /opt/android-ndk (this value sets by default)

  Asterisk (*) marks default values


To build ffmpeg for armeabi-v7a (with NEON optimization):
  ./ffmpeg-android-build.sh --api-level 10 --target armeabi-v7a --compiller-version 4.8 --ndk-home /opt/android-ndk


Tested only with:
  - NDK: r9
  - SDK: r22.2.1


Binary builds
-------------

Binary builds located at the `targets/TARGET` subdirectory.

Binary builds also located in GIT repository and can be reseived:

