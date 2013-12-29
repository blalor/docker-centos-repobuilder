#!/bin/bash

set -e
set -x

git clone https://github.com/chenyf/wsh.git /tmp/wsh
pushd /tmp/wsh

ver=$( git rev-parse --short HEAD )

## use committer's timestamp as epoch, as we're using a non-semver version
epoch=$( git log -n 1 --format=format:"%ct" ${ver} )

make
cp wsh wshd /usr/local/bin

popd

fpm \
    -s dir \
    -t rpm \
    -n wsh \
    -v ${ver} \
    --epoch ${epoch} \
    --url https://github.com/chenyf/wsh \
    --description "execute command in a Linux Container through unix socket" \
    /usr/local/bin/{wsh,wshd}
