#!/bin/bash
set -e

ARG=$1
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$ROOT_DIR/test"
SCRIPTS_DIR="$ROOT_DIR/../scripts"
PLUGIN_SUPPORT_DIR="$ROOT_DIR/../plugin-tests-support"
API=$(<"$SCRIPTS_DIR/.current_android_api")
RESOLUTION=$(<"$PLUGIN_SUPPORT_DIR/.android-resolution")
DEVICES_COUNT=2
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    ABI="arm64-v8a"
else
    ABI="x86_64"
fi
EMULATOR_PACKAGE="system-images;android-$API;google_apis;$ABI"
PROPERTIES_FILE="$TEST_DIR/local.properties"

publish_testcop_testng () {
    local library_dir="$ROOT_DIR/../android/library"
    local java_home="${JAVA_17_HOME:-${JDK_17_HOME:-${JAVA_HOME_17:-}}}"
    cd "$library_dir"
    if [[ -n "$java_home" ]]; then
        JAVA_HOME="$java_home" ./gradlew :testcop-testng:publishToMavenLocal -PallowHigherJavaVersion=true
    else
        ./gradlew :testcop-testng:publishToMavenLocal -PallowHigherJavaVersion=true
    fi
    cd "$TEST_DIR"
}

write_property () {
    if [ ! -f "$PROPERTIES_FILE" ]; then
        touch "$PROPERTIES_FILE"
    fi
    sed -i '' "/$1/d" "$PROPERTIES_FILE"
    echo "$1=$2" >> "$PROPERTIES_FILE"
}

prepare_android_env () {
    export FORCE_API=$API
    . "$SCRIPTS_DIR/android/emulator/prepare_android_env.sh" --run-test-local True --copy-from-resource False
}

if [[ $ARG == "switch-sdk-internal" || $ARG == "bootstrap-ios" ]]; then
    "$PLUGIN_SUPPORT_DIR/switch_sdk_spi.sh" "$ROOT_DIR/android/build.gradle" internal
    "$PLUGIN_SUPPORT_DIR/switch_sdk_spi.sh" "$ROOT_DIR/internal_test_app/android/app/build.gradle" internal
    "$PLUGIN_SUPPORT_DIR/switch_sdk_spi.sh" "$ROOT_DIR/ios/yandex_mobileads.podspec" internal
fi

if [[ $ARG == "recreate-android-emulators" || $ARG == "bootstrap-android" ]]; then
    cd "$SCRIPTS_DIR"
    prepare_android_env
    . android/plugin-emulator/create_emulator.sh "$EMULATOR_PACKAGE" "$DEVICES_COUNT"
    cd "$TEST_DIR"
fi

if [[ $ARG == "start-android-emulators" || $ARG == "bootstrap-android" ]]; then
    cd "$SCRIPTS_DIR"
    prepare_android_env
    for id in $(seq 1 $DEVICES_COUNT)
    do
        . android/plugin-emulator/start_emulator.sh "$id" "$RESOLUTION" "yes"
    done
    . android/emulator/await_all_devices_boot.sh "$DEVICES_COUNT"
    cd "$TEST_DIR"
fi

if [[ $ARG == "build-apk" || $ARG == "bootstrap-android" ]]; then
    cd "$ROOT_DIR"
    "$PLUGIN_SUPPORT_DIR/switch_sdk_spi.sh" android/build.gradle internal
    "$PLUGIN_SUPPORT_DIR/switch_sdk_spi.sh" internal_test_app/android/app/build.gradle internal
    cd "$ROOT_DIR/internal_test_app"
    flutter build apk --no-obfuscate -v
    cd "$ROOT_DIR"
    "$PLUGIN_SUPPORT_DIR/switch_sdk_spi.sh" android/build.gradle public
    "$PLUGIN_SUPPORT_DIR/switch_sdk_spi.sh" internal_test_app/android/app/build.gradle public
    cd "$TEST_DIR"
fi

if [[ $ARG == "run-all-tests-android" || $ARG == "bootstrap-android" ]]; then
    publish_testcop_testng
    export APP_PATH="$ROOT_DIR/internal_test_app/build/app/outputs/flutter-apk/app-release.apk"
    write_property platform android
    npm install
    ./gradlew test
fi

if [[ $ARG == "recreate-simulators" || $ARG == "bootstrap-ios" ]]; then
    for id in 1 2
    do
        xcrun simctl create "Test Device $id" com.apple.CoreSimulator.SimDeviceType.iPhone-15 com.apple.CoreSimulator.SimRuntime.iOS-18-5
    done
fi

if [[ $ARG == "build-ios" || $ARG == "bootstrap-ios" ]]; then
    cd "$ROOT_DIR"
    "$PLUGIN_SUPPORT_DIR/switch_sdk_spi.sh" ios/yandex_mobileads.podspec internal
    cd "$ROOT_DIR/internal_test_app"
    INTERNAL_BUILD=true flutter build ios --no-codesign --simulator --flavor RunnerInternal
    cd "$ROOT_DIR"
    "$PLUGIN_SUPPORT_DIR/switch_sdk_spi.sh" ios/yandex_mobileads.podspec public
    cd "$TEST_DIR"
fi

if [[ $ARG == "run-all-tests-ios" || $ARG == "bootstrap-ios" ]]; then
    publish_testcop_testng
    source "$SCRIPTS_DIR/build_web_driver_agent.sh"
    export APP_PATH="$ROOT_DIR/internal_test_app/build/ios/iphonesimulator/Runner.app"
    write_property platform ios
    npm install
    ./gradlew test
fi

if [[ $ARG == "switch-sdk-public" ]]; then
    "$PLUGIN_SUPPORT_DIR/switch_sdk_spi.sh" "$ROOT_DIR/android/build.gradle" public
    "$PLUGIN_SUPPORT_DIR/switch_sdk_spi.sh" "$ROOT_DIR/internal_test_app/android/app/build.gradle" public
    "$PLUGIN_SUPPORT_DIR/switch_sdk_spi.sh" "$ROOT_DIR/ios/yandex_mobileads.podspec" public
fi
