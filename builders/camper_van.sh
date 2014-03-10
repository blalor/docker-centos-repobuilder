#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

## Figuring out the full dependency tree and what's already available via yum is
## totally manual.  This script reflects that state, but there's probably a
## better way…

## remove charset warnings
export LC_CTYPE="en_US.UTF-8"
export LANG="en_US.UTF-8"
unset LC_ALL

function build_ruby193_pkg() {
    pkg=$1
    ver=$2
    
    pkg_exists_in_repo ruby193-rubygem-${pkg}-${ver} || \
        fpm \
            -s gem \
            -t rpm \
            --gem-package-name-prefix ruby193-rubygem \
            -d ruby193-ruby \
            -v ${ver} \
            ${pkg}
}

if ! pkg_exists_in_repo ruby193-rubygem-camper_van-0.0.15 ; then
    ## openssl-devel required for eventmachine to build with encryption support
    yum install -y centos-release-SCL openssl-devel

    yum install --disablerepo=* --enablerepo=scl -y ruby193-ruby-devel ruby193-rubygem-json

    ## gotta be a better way
    export LD_LIBRARY_PATH="$( scl enable ruby193 'echo ${LD_LIBRARY_PATH}' )"
    export PATH="$( scl enable ruby193 'echo ${PATH}' )"
    export PKG_CONFIG_PATH="$( scl enable ruby193 'echo ${PKG_CONFIG_PATH}' )"

    gem install --no-ri --no-rdoc fpm

    build_ruby193_pkg addressable     2.3.5
    build_ruby193_pkg camper_van      0.0.15
    build_ruby193_pkg cookiejar       0.3.1
    build_ruby193_pkg em-http-request 1.0.3
    build_ruby193_pkg em-socksify     0.3.0
    build_ruby193_pkg eventmachine    1.0.3
    build_ruby193_pkg firering        1.3.0
    build_ruby193_pkg http_parser.rb  0.6.0
    build_ruby193_pkg little-plugger  1.1.3
    build_ruby193_pkg logging         1.5.2
    build_ruby193_pkg trollop         1.16.2
    build_ruby193_pkg yajl-ruby       0.7.9
fi
