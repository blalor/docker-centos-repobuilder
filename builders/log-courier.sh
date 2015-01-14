#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="log-courier"
PKG_VER="1.3"
PKG_ITER="1"

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}-${PKG_ITER}; then
    echo "${PKG_NAME}-${PKG_VER}-${PKG_ITER} already built"
else
    yum install -y golang

    destdir=${PWD}
    
    pushd ${tmpdir}
    
    curl -O -L https://github.com/driskell/log-courier/raw/v${PKG_VER}/contrib/rpm/log-courier.spec

    sed -i \
        -e "/BuildRequires: git/d"  \
        -e "/Requires: zeromq3/d"  \
        -e "s/^Version: 1.2/Version: ${PKG_VER}/"  \
        -e "s/^Release: .*/Release: ${PKG_ITER}/"  \
        -e "s/^make with=zmq3/make/"  \
        log-courier.spec
    
    spectool -C SOURCES/ -g log-courier.spec
    rpmbuild -ba -D "_topdir $PWD" log-courier.spec
    
    mv "RPMS/x86_64/${PKG_NAME}-${PKG_VER}-${PKG_ITER}.x86_64.rpm" ${destdir}/
    
    popd
fi
