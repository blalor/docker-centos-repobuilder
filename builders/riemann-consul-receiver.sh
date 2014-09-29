#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="riemann-consul-receiver"
PKG_VER="1.0.1"
PKG_ITER="1"

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}-${PKG_ITER}; then
    echo "${PKG_NAME}-${PKG_VER}-${PKG_ITER} already built"
else
    pushd ${tmpdir}
    
    yum install -y golang mercurial
    
    git clone https://github.com/bluestatedigital/riemann-consul-receiver.git ${PKG_NAME}

    pushd ${PKG_NAME}
    
    git checkout v${PKG_VER}
    
    make rpm
    
    mv stage/${PKG_NAME}-${PKG_VER}-*.rpm ${RPMS}/
fi
