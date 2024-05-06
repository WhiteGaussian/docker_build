#!/usr/bin/env bash

# tools.sh

# Copyright (c) 2024 Dungru Tsai
# Author: Dungru Tsai
# Email: octobersky.tw@gmail.com

# Initialize variables for option flags and parameters
init_value=0
prepare_value=0
apply_value=0
build_value=0
untar_value=0
clean_up_value=0
# Define an associative array where the key is the source tarball and the value is the target directory
# Only put the Original DCC Release tarball that we care
declare -A tarballs=(
    ["mt7915_20221209-a9012a.tar.xz"]="mt7915_mt_wifi"
    ["mt79xx_20221209-b9c02f.tar.xz"]="mt_wifi"
)
# Directory
SDK_BASE_DIR="mtk-wifi-mt79xx"
DL_BASE_DIR="mtk-wifi-mt79xx/dl"
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
    echo "Usage: $(basename $0) [-i|--init] [-p|--prepare] [-a|--apply] [-b|--build]"
    echo "  -i, --init            Init the build Env and get openwrt source code and checkout"
    echo "  -p, --prepare         Tar DL source directories into their respective new tarballs, and Modify the PKG_SOURCE"
    echo "  -a, --apply           COPY the SDK into the openwrt source from SDK folder"
    echo "  -b, --build           Build project"
    echo "  -c, --clean_up        Clean up DCC tarballs and Restore the PKG_SOURCE to original DCC release version"
    echo "  --untar               Untar DL source tarball to target directory"
    echo "  --tar                 Tar DL source directories into their respective tarballs"
    exit 1
}

################## Function ##################
untar() {
    local source_tarball="$1"
    local target_dir="$2"

    echo "Untarring $source_tarball to $target_dir"
    mkdir -p "$DL_BASE_DIR/$target_dir"
    tar --exclude-vcs -xvf "$DL_BASE_DIR/$source_tarball" -C "$DL_BASE_DIR/$target_dir"
}

# Function to tar a new tarball and change the new PKG_SOURCE
update_new_pkg_source() {
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
    tar -cJf "$DL_BASE_DIR/$new_tarball_name" -C "$DL_BASE_DIR/$target_dir" .
    update_new_pkg_source $base_tarball_name $new_tarball_name
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
clean_up() {
    local target_dir=$1
    local source_tarball=$2
    local base_tarball_name="${source_tarball%%.*}" # Remove the file extension
    local makefile_path=$(find $PACKAGE_BASE_DIR -type f -name 'Makefile' -exec grep -l "PKG_SOURCE:=$base_tarball_name" {} +)
    if [[ -n "$makefile_path" ]]; then
        sed -i "s/^PKG_SOURCE:=$base_tarball_name.*/PKG_SOURCE:=$source_tarball/" "$makefile_path"
        echo "Updated PKG_SOURCE in $makefile_path to $source_tarball"
        find $SDK_BASE_DIR -name "$base_tarball_name*-dcc-*tar.xz" -exec rm {} \;
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
            init_value=1
            ;;
        -p|--prepare)
            prepare_value=1
            ;;
        -a|--apply)
            apply_value=1
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
        -c|--clean_up)
            clean_up_value=1
            ;;
        *)
            # If an unknown option is provided, display usage information
            usage
            ;;
    esac
    shift
done

# Implement the actions based on the flags and parameters
if [[ "${init_value}" -eq 1 ]]; then
    echo "Option -i/--init was triggered"
    get_source
fi

if [[ "${prepare_value}" -eq 1 ]]; then
    echo "Option -p/--prepare was triggered"
    for source_tarball in "${!tarballs[@]}"; do
        tar_dir "${tarballs[$source_tarball]}" "$source_tarball"
    done
fi

if [[ "${apply_value}" -eq 1 ]]; then
    echo "Option -a/--apply was triggered"
    rsync -av $SDK_BASE_DIR/ openwrt/
    for source_tarball in "${!tarballs[@]}"; do
        rm -rf "openwrt/dl/${tarballs[$source_tarball]}"
    done
    prepare_feeds
fi

if [[ "${clean_up_value}" -eq 1 ]]; then
    for source_tarball in "${!tarballs[@]}"; do
        clean_up "${tarballs[$source_tarball]}" "$source_tarball"
    done
fi

if [[ "${build_value}" -eq 1 ]]; then
    echo "Option -b/--build was triggered"
    build_1st_time
fi

if [[ "${untar_value}" -eq 1 ]]; then
    for source_tarball in "${!tarballs[@]}"; do
        untar "$source_tarball" "${tarballs[$source_tarball]}"
    done
fi

if [[ "${tar_value}" -eq 1 ]]; then
    for source_tarball in "${!tarballs[@]}"; do
        tar_dir "${tarballs[$source_tarball]}" "$source_tarball"
    done
fi
