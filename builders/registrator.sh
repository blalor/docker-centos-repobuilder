#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
# trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="registrator"
REPO="https://github.com/blalor/${PKG_NAME}.git"

PKG_ITER="1"
PKG_VER="520d22f"
GIT_REF="${PKG_VER}" ## might be "v${PKG_VER}" for a tag

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}-${PKG_ITER}; then
    echo "${PKG_NAME}-${PKG_VER}-${PKG_ITER} already built"
else
    yum install -y golang mercurial
    
    git clone ${REPO} ${tmpdir}

    pushd ${tmpdir}
    git checkout ${GIT_REF}
    
    make rpm
    
    mv target/${PKG_NAME}-${PKG_VER}-*.rpm ${RPMS}/
fi
