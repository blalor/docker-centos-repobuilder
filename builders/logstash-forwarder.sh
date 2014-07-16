#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="logstash-forwarder"
PKG_VER="69142e7"

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}; then
    echo "${PKG_NAME}-${PKG_VER} already built"
else
    destdir=${PWD}
    
    git clone https://github.com/elasticsearch/logstash-forwarder.git ${tmpdir}
    pushd ${tmpdir}
    
    git checkout ${PKG_VER}
    
    ## https://github.com/elasticsearch/logstash-forwarder/issues/226
    yum install -y golang-1.2.2
    
    ## doesn't set the epoch; necessary when using a non-semantic version
    # make VERSION=${PKG_VER} rpm
    make build-all
    
    fpm -s dir -t rpm -n logstash-forwarder -v ${PKG_VER} \
        --epoch $( git log --format=format:'%ct' --max-count=1 ${PKG_VER} ) \
        --replaces lumberjack \
        --exclude '*.a' --exclude 'lib/pkgconfig/zlib.pc' \
        --description "a log shipping tool" \
        --url "https://github.com/elasticsearch/logstash-forwarder" \
        build/bin/logstash-forwarder=/opt/logstash-forwarder/bin/ \
        build/bin/logstash-forwarder.sh=/opt/logstash-forwarder/bin/ \
        logstash-forwarder.init=/etc/init.d/logstash-forwarder
    
    mv "${PKG_NAME}-${PKG_VER}-1.x86_64.rpm" ${destdir}/
    
    popd
fi
