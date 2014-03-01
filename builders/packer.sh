#!/bin/bash

set -e -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PACKER_VER="0.5.1"
PACKER_ARCHIVE="${PACKER_VER}_linux_amd64.zip"
PACKER_URL_BASE="https://dl.bintray.com/mitchellh/packer"

if pkg_exists_in_repo packer-${PACKER_VER}; then
    echo "packer-${PACKER_VER} already built"
else
    pushd ${tmpdir}
    
    mkdir -p usr/local/packer/bin
    
    ## retrieve archive and checksum
    curl -L --remote-name-all ${PACKER_URL_BASE}/${PACKER_ARCHIVE} ${PACKER_URL_BASE}/${PACKER_VER}_SHA256SUMS
    
    ## compare checksum
    grep ${PACKER_ARCHIVE} ${PACKER_VER}_SHA256SUMS | sha256sum -c -
    
    ## unpack
    ( cd usr/local/packer/bin && unzip ${tmpdir}/${PACKER_ARCHIVE} )
    
    popd
    
    fpm \
        -s dir \
        -t rpm \
        -n packer \
        -v ${PACKER_VER} \
        -C ${tmpdir} \
        usr/local/packer
fi
