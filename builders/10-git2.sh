#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="git"
PKG_VER="2.1.2"
PKG_ITER="1"
PKG_ARCHIVE="git-${PKG_VER}.tar.xz"
PKG_URL_BASE="https://www.kernel.org/pub/software/scm/git"

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}-${PKG_ITER}; then
    echo "${PKG_NAME}-${PKG_VER}-${PKG_ITER} already built"
else
    pushd ${tmpdir}
    
    yum install -y zlib-devel perl-ExtUtils-MakeMaker openssl-devel libcurl-devel
    
    ## retrieve archive
    curl --remote-name-all --location ${PKG_URL_BASE}/${PKG_ARCHIVE}
    
    ## unpack
    xzcat ${PKG_ARCHIVE} | tar -x
    
    pushd ${PKG_NAME}-${PKG_VER}
    ./configure --prefix=/opt/git2 --with-openssl
    make
    make install DESTDIR=${tmpdir}/installdir
    popd
    
    popd
    fpm \
        -s dir \
        -t rpm \
        -n "git2" \
        -v ${PKG_VER} \
        --iteration ${PKG_ITER} \
        -C ${tmpdir}/installdir \
        opt/git2
fi
