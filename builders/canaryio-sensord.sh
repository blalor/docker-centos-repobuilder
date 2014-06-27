#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="canaryio-sensord"
PKG_VER="0a4ceae"
PKG_ITER="2"

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}-${PKG_ITER}; then
    echo "${PKG_NAME}-${PKG_VER}-${PKG_ITER} already built"
else
    pushd ${tmpdir}
    
    mkdir -p opt/canary/bin go

    export GOPATH=${tmpdir}/go
    export PATH=${GOPATH}/bin:${PATH}
    
    ## need go, and fucking mercurial
    yum install -y golang mercurial

    ## oh for fuck's sake
    ## https://github.com/canaryio/sensord/issues/57
    ## https://github.com/canaryio/sensord/issues/67
    ## building newer libcurl
    if [ ! -e /opt/canary/bin/curl ]; then
        ## yay iterative development!
        
        curl -O -L http://curl.haxx.se/download/curl-7.37.0.tar.gz
        tar -xzf curl-7.37.0.tar.gz
        
        pushd curl-7.37.0
        
        ./configure --prefix=/opt/canary
        make install
        
        popd
    fi
        
    ## copy curl libs into our package root
    tar -cf - -C /opt/canary lib | tar -x -C opt/canary
    
    export PKG_CONFIG_PATH=/opt/canary/lib/pkgconfig:/usr/lib64/pkgconfig
    
    ## ensure curl is picked up by the compiled binary
    export CGO_LDFLAGS="-Wl,-rpath,/opt/canary/lib"

    ## godep required to build this package
    go get -v github.com/tools/godep
    
    git clone https://github.com/canaryio/sensord.git ${GOPATH}/src/github.com/canaryio/sensord
    
    pushd ${GOPATH}/src/github.com/canaryio/sensord
    git checkout ${PKG_VER}
    
    ## since we're using a non-released version of the source and the git has as
    ## the version number, we need an epoch to differentiate old versions from
    ## new.
    PKG_EPOCH=$( git show ${PKG_VER} --format=format:'%ct' )
    
    godep get
    godep go build -v
    
    cp sensord ${tmpdir}/opt/canary/bin/
    
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
