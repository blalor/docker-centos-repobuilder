#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

NODE_VER="0.10.24"
NODE_ARCHIVE="node-v${NODE_VER}-linux-x64.tar.gz"
NODE_URL_BASE="http://nodejs.org/dist/v${NODE_VER}"

if pkg_exists_in_repo nodejs-${NODE_VER}; then
    echo "nodejs-${NODE_VER} already built"
else
    pushd ${tmpdir}
    
    mkdir -p usr/local
    
    ## retrieve archive and checksum
    curl --remote-name-all ${NODE_URL_BASE}/${NODE_ARCHIVE} ${NODE_URL_BASE}/SHASUMS.txt
    
    ## compare checksum
    grep $NODE_ARCHIVE SHASUMS.txt | sha1sum -c -
    
    ## unpack
    tar -xz --strip-components=1 -f ${NODE_ARCHIVE} -C usr/local
    
    ## remove stuff we don't need; README.md, ChangeLog, etc.
    find usr/local -maxdepth 1 -type f -print -exec rm {} \;
    
    popd
    fpm \
        -s dir \
        -t rpm \
        -n nodejs \
        -v ${NODE_VER} \
        -C ${tmpdir} \
        usr/local
fi
