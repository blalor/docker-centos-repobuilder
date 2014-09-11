#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="consul"
PKG_VER="0.3.1"
PKG_ITER="2"
PKG_ARCHIVE="${PKG_VER}_linux_amd64.zip"
PKG_ARCHIVE_UI="${PKG_VER}_web_ui.zip"
PKG_URL_BASE="https://dl.bintray.com/mitchellh/consul"

SOURCES_DIR="${SOURCES}/${PKG_NAME}"

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}-${PKG_ITER}; then
    echo "${PKG_NAME}-${PKG_VER}-${PKG_ITER} already built"
else
    pushd ${tmpdir}
    
    ## retrieve archive
    curl --remote-name-all --location ${PKG_URL_BASE}/${PKG_ARCHIVE} ${PKG_URL_BASE}/${PKG_ARCHIVE_UI}
    
    ## create required directories
    mkdir -p usr/bin etc/consul.d var/lib/consul etc/rc.d/init.d etc/logrotate.d usr/share/consul
    
    ## set dir perms
    chmod 550 etc/consul.d
    chmod 750 var/lib/consul
    
    ## unpack
    unzip ${PKG_ARCHIVE}
    mv consul usr/bin/consul
    chmod 555 usr/bin/consul
    
    unzip ${PKG_ARCHIVE_UI}
    mv dist usr/share/consul/ui

    ## config file
    cp "${SOURCES_DIR}/consul.conf" etc/consul.conf
    cp "${SOURCES_DIR}/consul.logrotate" etc/logrotate.d/consul
    
    ## init script
    cp "${SOURCES_DIR}/sysvinit.sh" etc/rc.d/init.d/consul
    chmod 555 etc/rc.d/init.d/consul    
    
    popd
    fpm \
        -s dir \
        -t rpm \
        -n ${PKG_NAME} \
        -v ${PKG_VER} \
        --iteration ${PKG_ITER} \
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
