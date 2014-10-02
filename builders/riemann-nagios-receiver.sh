#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="riemann-nagios-receiver"
PKG_VER="1.2.0"
PKG_ITER="1"

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}-${PKG_ITER}; then
    echo "${PKG_NAME}-${PKG_VER}-${PKG_ITER} already built"
else
    pushd ${tmpdir}
    
    ## https://twitter.com/gniemeyer/status/472318780472045568
    ##   If your "go get" seems to hang when using gopkg.in, update your git to >= 1.7.9.5. Thanks to @pebbe for the notice.
    yum install -y golang mercurial
    yum localinstall -y /rpms/git2*.rpm
    export PATH="/opt/git2/bin:${PATH}"
    
    git clone https://github.com/bluestatedigital/riemann-nagios-receiver.git ${PKG_NAME}

    pushd ${PKG_NAME}
    
    git checkout v${PKG_VER}
    
    make rpm
    
    mv stage/${PKG_NAME}-${PKG_VER}-*.rpm ${RPMS}/
fi
