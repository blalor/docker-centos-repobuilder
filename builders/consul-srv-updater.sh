#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="consul-srv-updater"
PKG_VER="1.0.2"
PKG_ITER="1"

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}-${PKG_ITER}; then
    echo "${PKG_NAME}-${PKG_VER}-${PKG_ITER} already built"
else
    pushd ${tmpdir}
    
    yum install -y golang
    
    git clone https://github.com/bluestatedigital/consul-srv-updater.git ${PKG_NAME}

    pushd ${PKG_NAME}
    
    git checkout v${PKG_VER}
    
    make
    
    popd
    
    mkdir -p usr/bin var/lib/${PKG_NAME}
    chmod 700 var/lib/${PKG_NAME}/
    
    cp ${PKG_NAME}/stage/${PKG_NAME} usr/bin/
    chmod 755 usr/bin/${PKG_NAME}
    
    popd
    
    fpm \
        -s dir \
        -t rpm \
        -n ${PKG_NAME} \
        -v ${PKG_VER} \
        --iteration ${PKG_ITER} \
        --rpm-use-file-permissions \
        -C ${tmpdir} \
        usr/bin/${PKG_NAME} \
        var/lib/${PKG_NAME}
fi
