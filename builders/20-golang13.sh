#!/bin/bash

set -e -x -u

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="golang13"
PKG_VER="1.3.3"
PKG_ITER="1"
PKG_ARCHIVE="go${PKG_VER}.linux-amd64.tar.gz"
PKG_URL_BASE="https://storage.googleapis.com/golang"

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}-${PKG_ITER}; then
    echo "${PKG_NAME}-${PKG_VER}-${PKG_ITER} already built"
else
    pushd ${tmpdir}
    
    ## retrieve archive
    curl --remote-name-all --location ${PKG_URL_BASE}/${PKG_ARCHIVE}
    
    ## unpack
    mkdir -p opt/${PKG_NAME}
    tar -xz --strip-components=1 -C opt/${PKG_NAME} -f ${PKG_ARCHIVE} 
    
    popd
    
    fpm \
        -s dir \
        -t rpm \
        -n ${PKG_NAME} \
        -v ${PKG_VER} \
        --iteration ${PKG_ITER} \
        -C ${tmpdir} \
        opt/${PKG_NAME}
fi
