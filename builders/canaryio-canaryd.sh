#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="canaryio-canaryd"
PKG_VER="626e025"
PKG_ITER="1"

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}-${PKG_ITER}; then
    echo "${PKG_NAME}-${PKG_VER}-${PKG_ITER} already built"
else
    pushd ${tmpdir}
    
    mkdir -p opt/canary/bin go

    export GOPATH=${tmpdir}/go
    export PATH=${GOPATH}/bin:${PATH}
    
    ## need go, and fucking mercurial
    yum install -y golang mercurial
    
    ## godep required to build this package
    go get -v github.com/tools/godep
    
    git clone https://github.com/canaryio/canaryd.git ${GOPATH}/src/github.com/canaryio/canaryd
    
    pushd ${GOPATH}/src/github.com/canaryio/canaryd
    git checkout ${PKG_VER}
    
    ## since we're using a non-released version of the source and the git has as
    ## the version number, we need an epoch to differentiate old versions from
    ## new.
    PKG_EPOCH=$( git show ${PKG_VER} --format=format:'%ct' )

    godep get
    godep go build -v
    
    cp canaryd ${tmpdir}/opt/canary/bin/
    
    popd
    
    popd
    fpm \
        -s dir \
        -t rpm \
        -n ${PKG_NAME} \
        -v ${PKG_VER} \
        --epoch ${PKG_EPOCH} \
        --iteration ${PKG_ITER} \
        --rpm-use-file-permissions \
        -C ${tmpdir} \
        opt/canary
fi
