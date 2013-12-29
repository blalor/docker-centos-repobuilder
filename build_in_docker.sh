#!/bin/bash

basedir=$( cd $( dirname $0 ) && /bin/pwd )

[ -d ${basedir}/rpms ] || mkdir -p ${basedir}/rpms

docker run \
    -v ${basedir}:/scripts \
    -v ${basedir}/rpms:/rpms \
    -e AWS_ACCESS_KEY \
    -e AWS_SECRET_KEY \
    -e BUCKET \
    -e REPO \
    blalor/centos-buildtools:latest \
    /scripts/build_all.sh
