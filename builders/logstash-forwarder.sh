#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG="logstash-forwarder"
VER="0.3.1"

if pkg_exists_in_repo "${PKG}-${VER}"; then
    echo "${PKG}-${VER} already built"
else
    destdir=${PWD}
    
    git clone https://github.com/elasticsearch/logstash-forwarder.git ${tmpdir}
    pushd ${tmpdir}
    
    git checkout d2ba8895471252c2e3c12abd1a3a72f2fcbdb4bd
    
    yum install -y golang
    
    make rpm
    
    mv "${PKG}-${VER}-1.x86_64.rpm" ${destdir}/
    
    popd
fi
