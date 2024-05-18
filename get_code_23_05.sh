#!/usr/bin/env bash
 
s_value=0
p_value=0
b_value=0

#export DOCKERQ_IMAGE=
while getopts ":spb" option; do
    case "${option}" in
        s)
            s_value=1
            ;;
        p)
            p_value=1
            ;;
        b)
            b_value=1
            ;;
        :)
            echo "Error: -${OPTARG} requires an argument."
            exit 1
            ;;
        *)
            echo "Usage: $(basename $0) [-s get source] [-p prepare] [-b build]"
            exit 1
            ;;
    esac
done
 
echo "s = ${s_value}"
echo "p = ${p_value}"
echo "b = ${b_value}"
 
# Get the source code
if [ $s_value -eq 1 ]; then
    git clone --branch openwrt-23.05 https://git.openwrt.org/openwrt/openwrt.git
    pushd openwrt
    popd
    cp -rf autobuild/  openwrt/
fi
# Release wiki page: https://wiki.mediatek.inc/pages/viewpage.action?pageId=1451298100
# Prepare
if [ $p_value -eq 1 ]; then
    echo "prepare"
    pushd openwrt
#    sed -i 's/feeds.conf.default$/feeds.conf/' ./autobuild/lede-build-sanity.sh
#    cp feeds.conf.default feeds.conf
#    echo "src-git mtk_openwrt_feed https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds" >> feeds.conf
#    echo "src-git dpdk_repo https://github.com/k13132/openwrt-dpdk" >> feeds.conf
    cp feeds.conf.default autobuild/feeds.conf.default-23.05
    cp feeds.conf.default autobuild/feeds.conf.default
    echo "src-git mtk_openwrt_feed https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds" >> autobuild/feeds.conf.default-23.05
    echo "src-git dpdk_repo https://github.com/k13132/openwrt-dpdk" >> autobuild/feeds.conf.default-23.05
    popd
fi
 
# Build the code 1st time
if [ $b_value -eq 1 ]; then
    pushd openwrt/
    dockerq22 ./autobuild/mt7988-trunk-iap/lede-branch-build-sanity.sh
    popd
fi
