#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="logstash-forwarder"
PKG_ITER="1"

## https://github.com/elasticsearch/logstash-forwarder/pull/285
## https://github.com/elasticsearch/logstash-forwarder/pull/154
PKG_VER="0632ce3" 
REPO="https://github.com/elasticsearch/logstash-forwarder.git"

SOURCES_DIR="${SOURCES}/${PKG_NAME}"

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}; then
    echo "${PKG_NAME}-${PKG_VER} already built"
else
    destdir=${PWD}
    
    git clone ${REPO} ${tmpdir}
    pushd ${tmpdir}
    
    git checkout ${PKG_VER}
    
    ## requires golang 1.3, which is now in epel (as of 2014-Oct-31)
    ## https://github.com/elasticsearch/logstash-forwarder/issues/226
    yum install -y golang
    
    ## doesn't set the epoch; necessary when using a non-semantic version
    # make VERSION=${PKG_VER} rpm
    make build-all
    
    fpm \
        -s dir \
        -t rpm \
        -n logstash-forwarder \
        -v ${PKG_VER} \
        --iteration ${PKG_ITER} \
        --epoch $( git log --format=format:'%ct' --max-count=1 ${PKG_VER} ) \
        --replaces lumberjack \
        --description "a log shipping tool" \
        --url "https://github.com/elasticsearch/logstash-forwarder" \
        build/bin/logstash-forwarder=/usr/bin/ \
        ${SOURCES_DIR}/sysvinit=/etc/rc.d/init.d/logstash-forwarder \
        ${SOURCES_DIR}/logrotate=/etc/logrotate.d/logstash-forwarder
    
    mv "${PKG_NAME}-${PKG_VER}-1.x86_64.rpm" ${destdir}/
    
    popd
fi
