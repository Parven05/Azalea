#!/usr/bin/env bash

BUILD_DIR="build"          # CMake build directory
BIN_DIR="bin"              # Where the executable is placed (refer in CMakeLists.txt)
EXECUTABLE="main"          # Executable name (refer in CMakeLists.txt)
BUILD_TYPE="Debug"         # Default build type: Debug or Release
JOBS=""                    # Parallel jobs. Empty = plain -j, or set e.g. "8"
DO_CLEAN=0
DO_BUILD=0
DO_RUN=0

usage() {
    echo "Usage: ./build.sh [flags]"
    echo ""
    echo "Flags:"
    echo "  -d, --debug     Use Debug build type (default)"
    echo "  -r, --release   Use Release build type"
    echo "  -c, --clean     Remove the build directory and executable"
    echo "  -b, --build     Build only (default if no action flag is given)"
    echo "  -x, --run       Build, then run the executable"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  ./build.sh                 # debug build"
    echo "  ./build.sh -r              # release build"
    echo "  ./build.sh -c              # clean only"
    echo "  ./build.sh -c -r -b        # clean, then release build"
    echo "  ./build.sh -x              # debug build and run"
    echo "  ./build.sh -r -x           # release build and run"
}

# parse flags
for arg in "$@"; do
    case "$arg" in
        -d|--debug)   BUILD_TYPE="Debug" ;;
        -r|--release) BUILD_TYPE="Release" ;;
        -c|--clean)   DO_CLEAN=1 ;;
        -b|--build)   DO_BUILD=1 ;;
        -x|--run)     DO_BUILD=1; DO_RUN=1 ;;
        -h|--help)    usage; exit 0 ;;
        *)
            echo "Unknown flag: $arg"
            usage
            exit 1
            ;;
    esac
done

# default to build only
if [ $DO_CLEAN -eq 0 ] && [ $DO_BUILD -eq 0 ]; then
    DO_BUILD=1
fi

cd "$(dirname "$0")" || exit 1
set -e

# actions
if [ $DO_CLEAN -eq 1 ]; then
    echo "==> Cleaning"
    rm -rf "$BUILD_DIR"
    rm -f "$BIN_DIR/$EXECUTABLE"
fi

if [ $DO_BUILD -eq 1 ]; then
    echo "==> Building ($BUILD_TYPE)"
    cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
    cmake --build "$BUILD_DIR" -j$JOBS
fi

if [ $DO_RUN -eq 1 ]; then
    echo "==> Running"
    "./$BIN_DIR/$EXECUTABLE"
fi