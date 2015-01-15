
#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

tmpdir=$( mktemp -d )
trap "echo removing ${tmpdir}; rm -rf ${tmpdir}" EXIT

PKG_NAME="ngx_openresty"
PKG_VER="1.7.7.1"
PKG_ITER="1"
PKG_ARCHIVE="${PKG_NAME}-${PKG_VER}.tar.gz"
PKG_URL_BASE="http://openresty.org/download"

if pkg_exists_in_repo ${PKG_NAME}-${PKG_VER}-${PKG_ITER}; then
    echo "${PKG_NAME}-${PKG_VER}-${PKG_ITER} already built"
else
    pushd ${tmpdir}
    
    yum install -y readline-devel pcre-devel openssl-devel
    
    ## retrieve archive
    curl --remote-name-all --location ${PKG_URL_BASE}/${PKG_ARCHIVE}
    
    ## unpack
    tar -xzf ${PKG_ARCHIVE}
    
    pushd ${PKG_NAME}-${PKG_VER}
    ./configure --prefix=/opt/openresty
    make
    make install DESTDIR=${tmpdir}/installdir
    popd
    
    popd
    fpm \
        -s dir \
        -t rpm \
        -n ${PKG_NAME} \
        -v ${PKG_VER} \
        --iteration ${PKG_ITER} \
        -d openssl \
        -d pcre \
        -C ${tmpdir}/installdir \
        opt/openresty
fi
