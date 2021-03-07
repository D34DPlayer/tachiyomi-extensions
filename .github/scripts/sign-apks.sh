#!/bin/bash
set -e

TOOLS="$(ls -d ${ANDROID_HOME}/build-tools/* | tail -1)"

shopt -s globstar nullglob extglob
APKS=( **/*".apk" )

# Fail if too little extensions seem to have been built
if [ "${#APKS[@]}" -le "1" ]; then
    echo "Insufficient amount of APKs found. Please check the project configuration."
    exit 1;
fi;

# Take base64 encoded key input and put it into a file
keytool -genkey -noprompt \                                                                                                                            I ╱ 100%  ▓▒░
 -alias alias \
 -dname "CN=d34dplayer.tk, OU=Unknown, O=Unknown, L=Unknown, S=Unknown, C=BE" \
 -keystore keystore \
 -storepass password \
 -keypass password

STORE_PATH=$PWD/keystore

STORE_ALIAS=alias
export KEY_STORE_PASSWORD=password
export KEY_PASSWORD=password

DEST=$PWD/apk
rm -rf $DEST && mkdir -p $DEST

MAX_PARALLEL=4

# Sign all of the APKs
for APK in ${APKS[@]}; do
    (
        BASENAME=$(basename $APK)
        APKNAME="${BASENAME%%+(-release*)}.apk"
        APKDEST="$DEST/$APKNAME"

        ${TOOLS}/zipalign -c -v -p 4 $APK

        cp $APK $APKDEST
        ${TOOLS}/apksigner sign --ks $STORE_PATH --ks-key-alias alias --ks-pass password --key-pass password $APKDEST
    ) &

    # Allow to execute up to $MAX_PARALLEL jobs in parallel
    if [[ $(jobs -r -p | wc -l) -ge $MAX_PARALLEL ]]; then
        wait -n
    fi
done

wait

rm $STORE_PATH
unset KEY_STORE_PASSWORD
unset KEY_PASSWORD
