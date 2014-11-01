#!/bin/bash

## build RPMs for collectd

set -e -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="nsenter"
PKG_VER="2.25"
PKG_ITER="2"
PKG_ARCHIVE="util-linux-${PKG_VER}.tar.gz"
PKG_URL_BASE="https://www.kernel.org/pub/linux/utils/util-linux/v${PKG_VER}"

SOURCES_DIR="${SOURCES}/${PKG_NAME}"

if pkg_exists_in_repo "${PKG_NAME}-${PKG_VER}"; then
    echo "${PKG_NAME}-${PKG_VER} already built"
else
    destdir=${PWD}

    pushd ${tmpdir}
    
    ## stolen from
    ## https://github.com/jpetazzo/nsenter/blob/c5e9a3c339d25e6d7f671d3d8d78fea6f15f956b/Dockerfile
    curl --remote-name-all --location ${PKG_URL_BASE}/${PKG_ARCHIVE}
    tar -xz --strip-components=1 -f ${PKG_ARCHIVE}

    ./configure --without-ncurses --without-python
    make LDFLAGS="-all-static" nsenter
    
    mkdir -p usr/local/bin
    mv nsenter usr/local/bin/
    cp ${SOURCES_DIR}/* usr/local/bin/
    chmod 555 usr/local/bin/*
    
    popd
    
    fpm \
        -s dir \
        -t rpm \
        -n ${PKG_NAME} \
        -v ${PKG_VER} \
        --iteration ${PKG_ITER} \
        --rpm-use-file-permissions \
        -C ${tmpdir} \
        usr/local/bin
fi
