#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
# trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="consul"
PKG_VER="0.2.0"
PKG_ARCHIVE="${PKG_VER}_linux_amd64.zip"
PKG_URL_BASE="https://dl.bintray.com/mitchellh/consul"

SOURCES_DIR="${SOURCES}/${PKG_NAME}"

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}; then
    echo "${PKG_NAME}-${PKG_VER} already built"
else
    pushd ${tmpdir}
    
    ## retrieve archive
    curl --remote-name-all --location ${PKG_URL_BASE}/${PKG_ARCHIVE}
    
    ## create required directories
    mkdir -p usr/bin etc/consul.d var/lib/consul etc/rc.d/init.d
    
    chmod 550 etc/consul.d var/lib/consul
    
    ## unpack
    unzip ${PKG_ARCHIVE}
    mv consul usr/bin/consul
    chmod 555 usr/bin/consul

    ## config file
    cp "${SOURCES_DIR}/consul.conf" etc/consul.conf
    
    ## init script
    cp "${SOURCES_DIR}/sysvinit.sh" etc/rc.d/init.d/consul
    chmod 555 etc/rc.d/init.d/consul    
    
    popd
    fpm \
        -s dir \
        -t rpm \
        -n ${PKG_NAME} \
        -v ${PKG_VER} \
        --before-install "${SOURCES_DIR}/before-install.sh" \
        --rpm-user consul \
        --rpm-group consul \
        --rpm-use-file-permissions \
        --config-files /etc/consul.conf \
        --directories /etc/consul.d \
        --directories /var/lib/consul \
        -C ${tmpdir} \
        etc usr var
fi
