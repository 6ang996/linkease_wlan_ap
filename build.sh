#!/bin/bash

#set -ex
ROOT_PATH=${PWD}
BUILD_DIR=${ROOT_PATH}/openwrt
TARGET=linkease_x86_64
REPO=gitee

Usage(){
    cat <<EOF
Usage:
    $0 [-t target] [-p repo] [-s]       #第一次编译时需要执行此命令设置代码编译环境及拉取代码
    $0                                  #编译代码时执行此命令，不需要携带参数

    -t linkease_x86_64       (指定目标类型)
    -p [github|gitee] (设置openwrt代码源，openwrt代码默认为gitee)
    -s                       (初始化config配置及环境配置)

EOF
    exit 1
}

# 参数解析
while getopts "t:p:s" arg; do
    case $arg in
    t)
        TARGET=$OPTARG
        echo "TARGET: $TARGET" 
        ;;
    p)
        REPO=$OPTARG
        echo "repo: $REPO" 
        ;;
    s)
        SETUPCONFIG=setenv
        echo "SETUPCONFIG: $SETUPCONFIG" 
        ;;
    \?)  
        echo "unkonw argument"
        Usage
        ;;
    esac
done

if [ -z "${TARGET}" ]; then
	echo "Error: please specify TARGET"
    echo "For example: linkease_x86_64"
	exit 1
fi

if [ -n "${SETUPCONFIG}" ]; then
    if [ "A-${SETUPCONFIG}" == "A-setenv" ]; then
        if [ "A-${REPO}" == "A-github" ]; then
            sed -i "s=^repo:.*=repo: https://github.com/openwrt/openwrt.git=g" config.yml || true
        elif [ "A-${REPO}" == "A-gitee" ]; then
            sed -i "s=^repo:.*=repo: https://gitee.com/wlan-ap/openwrt.git=g" config.yml || true
        fi

        if [ ! "$(ls -A $BUILD_DIR)" ]; then
            python3 setup.py --setup || exit 1
        else
            python3 setup.py --rebase
            echo "### OpenWrt repo already setup"
        fi

        cd ${BUILD_DIR}
        if [ "A-${REPO}" == "A-github" ]; then
            sed -i "s= [a-z]*:.*/project= https://github.com/openwrt=g" feeds.conf.default || true
            sed -i 's= [a-z]*:.*/feed= https://github.com/openwrt=g' feeds.conf.default || true
        elif [ "A-${REPO}" == "A-gitee" ]; then
            sed -i "s= [a-z]*:.*/project= https://gitee.com/wlan-ap=g" feeds.conf.default || true
            sed -i "s= [a-z]*:.*/feed= https://gitee.com/wlan-ap=g" feeds.conf.default || true
        fi
        cd -

        cd ${BUILD_DIR}
        ./scripts/gen_config.py ${TARGET} || exit 1
        cd -

        cd ${BUILD_DIR}
        make -j$(nproc) download V=s || make download V=s IGNORE_ERRORS=1
        cd -
    fi
else
    echo "### Building image ..."
    cd $BUILD_DIR
    time make -j$(nproc) V=s || make -j1 V=s
fi
