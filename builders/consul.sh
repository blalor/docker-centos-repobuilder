#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="consul"
PKG_VER="0.2.0"
PKG_ARCHIVE="${PKG_VER}_linux_amd64.zip"
PKG_URL_BASE="https://dl.bintray.com/mitchellh/consul"

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}; then
    echo "${PKG_NAME}-${PKG_VER} already built"
else
    pushd ${tmpdir}
    
    mkdir -p usr/local
    
    ## retrieve archive
    curl --remote-name-all --location ${PKG_URL_BASE}/${PKG_ARCHIVE}
    
    ## unpack
    unzip ${PKG_ARCHIVE}
    mv consul usr/local/
    
    popd
    fpm \
        -s dir \
        -t rpm \
        -n ${PKG_NAME} \
        -v ${PKG_VER} \
        -C ${tmpdir} \
        usr/local
fi
