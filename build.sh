#!/bin/bash

set -e

AAPT="/home/dkleiven/Documents/android_devel/build-tools/28.0.2/aapt"
DX="/home/dkleiven/Documents/android_devel/build-tools/28.0.2/dx"
ZIPALIGN="/home/dkleiven/Documents/android_devel/build-tools/28.0.2/zipalign"
APKSIGNER="/home/dkleiven/Documents/android_devel/build-tools/28.0.2/apksigner" # /!\ version 26
PLATFORM="/home/dkleiven/Documents/android_devel/platforms/android-24/android.jar"
SRC_DIR="src/com/github/tuna"

echo "Cleaning..."
rm -rf obj/*
rm -rf $SRC_DIR/R.java

echo "Generating R.java file..."
$AAPT package -f -m -J src -M AndroidManifest.xml -S res -I $PLATFORM

echo "Compiling..."
javac -d obj -classpath src -bootclasspath $PLATFORM -source 1.7 -target 1.7 $SRC_DIR/MainActivity.java
javac -d obj -classpath src -bootclasspath $PLATFORM -source 1.7 -target 1.7 $SRC_DIR/R.java

echo "Translating in Dalvik bytecode..."
$DX --dex --output=classes.dex obj

echo "Making APK..."
$AAPT package -f -m -F bin/tuna.unaligned.apk -M AndroidManifest.xml -S res -I $PLATFORM
$AAPT add bin/tuna.unaligned.apk classes.dex

echo "Aligning and signing APK..."
$APKSIGNER sign --ks mykey.keystore bin/tuna.unaligned.apk
$ZIPALIGN -f 4 bin/tuna.unaligned.apk bin/tuna.apk

if [ "$1" == "test" ]; then
	echo "Launching..."
	adb install -r bin/tuna.apk
	adb shell am start -n com.github.tuna/.MainActivity
fi
