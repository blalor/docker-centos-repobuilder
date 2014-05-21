#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="nodejs"
PKG_VER="0.10.28"
PKG_ITER="1"
PKG_ARCHIVE="node-v${PKG_VER}-linux-x64.tar.gz"
PKG_URL_BASE="http://nodejs.org/dist/v${PKG_VER}"

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}-${PKG_ITER}; then
    echo "${PKG_NAME}-${PKG_VER}-${PKG_ITER} already built"
else
    pushd ${tmpdir}
    
    mkdir -p usr/local
    
    ## retrieve archive and checksum
    curl --remote-name-all ${PKG_URL_BASE}/${PKG_ARCHIVE} ${PKG_URL_BASE}/SHASUMS.txt
    
    ## compare checksum
    grep $PKG_ARCHIVE SHASUMS.txt | sha1sum -c -
    
    ## unpack
    tar -xz --strip-components=1 -f ${PKG_ARCHIVE} -C usr/local
    
    ## remove stuff we don't need; README.md, ChangeLog, etc.
    find usr/local -maxdepth 1 -type f -print -exec rm {} \;
    
    popd
    fpm \
        -s dir \
        -t rpm \
        -n ${PKG_NAME} \
        -v ${PKG_VER} \
        --iteration ${PKG_ITER} \
        --rpm-use-file-permissions \
        -C ${tmpdir} \
        usr/local
fi
