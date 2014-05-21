#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="redis"
SOURCES_DIR="${SOURCES}/${PKG_NAME}"

PKG_VER="$( egrep '^Version:' ${SOURCES_DIR}/SPECS/redis.spec | sed -r -e 's#^.*: +##g' )"
PKG_ITER="$( egrep '^Release:' ${SOURCES_DIR}/SPECS/redis.spec | sed -r -e 's#^.*: +##g' )"

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}-${PKG_ITER}; then
    echo "${PKG_NAME}-${PKG_VER}-${PKG_ITER} already built"
else
    tar -cf - -C ${SOURCES_DIR} . | tar -xf - -C ${tmpdir}
    chown -R root:root ${tmpdir}
    
    spec_file="${tmpdir}/SPECS/redis.spec"
    
    ## download sources
    spectool -g -C "${tmpdir}/SOURCES" -S ${spec_file}
    
    ## install build deps
    yum-builddep -y ${spec_file}

    ## build the mofo
    rpmbuild -D "_topdir ${tmpdir}" --bb ${spec_file}
    
    mv ${tmpdir}/RPMS/*/${PKG_NAME}-${PKG_VER}-${PKG_ITER}.*.rpm .
fi
