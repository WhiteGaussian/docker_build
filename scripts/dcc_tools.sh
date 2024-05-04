#!/usr/bin/env bash

# tools.sh

# Copyright (c) 2024 Dungru Tsai
# Author: Dungru Tsai
# Email: octobersky.tw@gmail.com

# Initialize variables for option flags and parameters
source_value=0
prepare_value=0
build_value=0
untar_value=0
restore_pkg_value=0
# Define an associative array where the key is the source tarball and the value is the target directory
# Only put the Original DCC Release tarball that we care
declare -A tarballs=(
    ["mt7915_20221209-a9012a.tar.xz"]="mt7915_mt_wifi"
    ["mt79xx_20221209-b9c02f.tar.xz"]="mt_wifi"
)
# Directory 
BASE_DIR="mtk-wifi-mt79xx/dl"
PACKAGE_BASE_DIR="mtk-wifi-mt79xx/package"
# Official DCC Release Note Commit
OPENWRT_COMMIT="295c612"
PACKAGE_COMMIT="c10f3e3"
LUCI_COMMIT="0ecaf74"
ROUTING_COMMIT="4e2bdb4"
MTK_OPENWRT_FEEDS_COMMIT="91c043c"
# Build SDK options
PROJECT_NAME="mt7986-AX8400"
BUILD_ARGUMENT="5g"

# Function to display usage information
usage() {
    echo "Usage: $(basename $0) [-s|--source] [-p|--prepare] [-b|--build]"
    echo "  -s, --get_source      Get openwrt source code and checkout"
    echo "  -p, --prepare         Prepare environment"
    echo "  -b, --build           Build project"
    echo "  --untar               Untar DL source tarball to target directory"
    echo "  --tar                 Tar DL source directories into their respective tarballs"
    echo "  --restore_pkg         Restore the PKG_SOURCE to original DCC release version"
    exit 1
}

################## Function ##################
untar() {
    local source_tarball="$1"
    local target_dir="$2"

    echo "Untarring $source_tarball to $target_dir"
    mkdir -p "$BASE_DIR/$target_dir"
    tar -xvf "$BASE_DIR/$source_tarball" -C "$BASE_DIR/$target_dir" --strip-components=1
}

# Function to tar a new tarball and change the new PKG_SOURCE
apply_new_tarball() {
    local base_tarball_name=$1
    local new_tarball_name=$2
    # Search for the Makefile path by base_tarball_name and replace PKG_SOURCE with new_tarball_name
    local makefile_path=$(find $PACKAGE_BASE_DIR -type f -name 'Makefile' -exec grep -l "PKG_SOURCE:=$base_tarball_name" {} +)
    if [[ -n "$makefile_path" ]]; then
        sed -i "s/^PKG_SOURCE:=$base_tarball_name.*/PKG_SOURCE:=$new_tarball_name/" "$makefile_path"
        echo "Updated PKG_SOURCE in $makefile_path to $new_tarball_name"
    else
        echo "Makefile not found for $source_tarball"
    fi
}

tar_dir() {
    local target_dir="$1"
    local source_tarball="$2"
    head_commit="dcc-$(git rev-parse --short=6 HEAD)"
    local base_tarball_name="${source_tarball%%.*}" # Remove the file extension
    local tarball_extension="${source_tarball##*.}" # Get the file extension
    local new_tarball_name="${base_tarball_name}-${head_commit}.tar.${tarball_extension}"
    echo "Tarring $target_dir into $new_tarball_name"
    tar -cvf "$BASE_DIR/$new_tarball_name" -C "$BASE_DIR/$target_dir" .
    apply_new_tarball $base_tarball_name $new_tarball_name
}

# Get Openwrt and source options

get_source() {
    git clone --branch openwrt-21.02 https://git.openwrt.org/openwrt/openwrt.git
    pushd openwrt
    git checkout $OPENWRT_COMMIT
    git checkout -b $OPENWRT_COMMIT
    popd
}

# Prepare the feeds
prepare_feeds() {
    pushd openwrt/
    sed -i 's/feeds.conf.default$/feeds.conf/' ./autobuild/lede-build-sanity.sh
    cp feeds.conf.default feeds.conf
    echo "src-git packages https://git.openwrt.org/feed/packages.git^$PACKAGE_COMMIT" > feeds.conf
    echo "src-git luci https://git.openwrt.org/project/luci.git^$LUCI_COMMIT" >> feeds.conf
    echo "src-git routing https://git.openwrt.org/feed/routing.git^$ROUTING_COMMIT" >> feeds.conf
    echo "src-git mtk_openwrt_feed https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds^$MTK_OPENWRT_FEEDS_COMMIT" >> feeds.conf
    echo "src-git-full telephony https://git.openwrt.org/feed/telephony.git;openwrt-21.02" >> feeds.conf
    popd
}

# 1st time buils

build_1st_time() {
    pushd openwrt/
    dockerq ./autobuild/$PROJECT_NAME/lede-branch-build-sanity.sh $BUILD_ARGUMENT
    popd
}

# Restore Package
restore_pkg() {
    local target_dir=$1
    local source_tarball=$2
    local base_tarball_name="${source_tarball%%.*}" # Remove the file extension
    local makefile_path=$(find $PACKAGE_BASE_DIR -type f -name 'Makefile' -exec grep -l "PKG_SOURCE:=$base_tarball_name" {} +)
    if [[ -n "$makefile_path" ]]; then
        sed -i "s/^PKG_SOURCE:=$base_tarball_name.*/PKG_SOURCE:=$source_tarball/" "$makefile_path"
        echo "Updated PKG_SOURCE in $makefile_path to $source_tarball"
    else
        echo "Makefile not found for $source_tarball"
    fi
}

# Check if no options were provided
if [ "$#" -eq 0 ]; then
    usage
fi

# Parse command-line options
while [[ "$#" -gt 0 ]]; do
    case "$1" in

        -s|--source)
            source_value=1
            ;;
        -p|--prepare)
            prepare_value=1
            ;;
        -b|--build)
            build_value=1
            ;;
        --untar)
            untar_value=1
            ;;
        --tar)
            tar_value=1
            ;;
        --restore_pkg)
            restore_pkg_value=1
            ;;
        *)
            # If an unknown option is provided, display usage information
            usage
            ;;
    esac
    shift
done

# Implement the actions based on the flags and parameters
if [ "${source_value}" -eq 1 ]; then
    echo "Option -s/--source was triggered"
    get_source
fi

if [ "${prepare_value}" -eq 1 ]; then
    echo "Option -p/--prepare was triggered"
    prepare_feeds
fi

if [ "${build_value}" -eq 1 ]; then
    echo "Option -b/--build was triggered"
    build_1st_time
fi

if [ "${untar_value}" -eq 1 ]; then
    for source_tarball in "${!tarballs[@]}"; do
        untar "$source_tarball" "${tarballs[$source_tarball]}"
    done
fi

if [ "${tar_value}" -eq 1 ]; then
    for source_tarball in "${!tarballs[@]}"; do
        tar_dir "${tarballs[$source_tarball]}" "$source_tarball"
    done
fi

if [ "${restore_pkg_value}" -eq 1 ]; then
    for source_tarball in "${!tarballs[@]}"; do
        restore_pkg "${tarballs[$source_tarball]}" "$source_tarball"
    done
fi
