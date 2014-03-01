#!/bin/bash

## build RPMs for collectd

set -e -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG="collectd"
VER="5.4.1"

if pkg_exists_in_repo "${PKG}-${VER}"; then
    echo "${PKG}-${VER} already built"
else
    destdir=${PWD}

    pushd ${tmpdir}
    
    topdir="${tmpdir}/rpmbuild"    
    ## required directory structure
    mkdir -p ${topdir}/{SPECS,SOURCES}
    
    spec_file="${topdir}/SPECS/collectd.spec"
    
    ## retrieve source
    curl -o ${topdir}/SOURCES/collectd-${VER}.tar.bz2 https://collectd.org/files/collectd-${VER}.tar.bz2
    
    ## extract spec file
    tar -xOjf ${topdir}/SOURCES/collectd-${VER}.tar.bz2 collectd-${VER}/contrib/redhat/collectd.spec > ${spec_file}
    
    ## update spec for current version
    sed -i -e "s#^Version:.*#Version: ${VER}#" ${spec_file}
    
    ## kludgy way to install required dev dependencies; probably a better way
    rpmbuild -D "_topdir ${topdir}" --bb ${spec_file} |& grep 'is needed' | awk '{print $1}' | xargs yum install -y
    
    ## now actually build it
    rpmbuild -D "_topdir ${topdir}" --bb ${spec_file}
    
    mv ${topdir}/RPMS/*/*.rpm ${destdir}/
    
    popd
fi
