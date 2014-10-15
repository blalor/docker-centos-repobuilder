#!/bin/bash

[ -z $AWS_ACCESS_KEY ] && echo "no value for AWS_ACCESS_KEY"
[ -z $AWS_SECRET_KEY ] && echo "no value for AWS_SECRET_KEY"
[ -z $BUCKET ]         && echo "no value for BUCKET"
[ -z $REPO ]           && echo "no value for REPO"

set -e

basedir=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

[ -d ${basedir}/rpms ] || mkdir -p ${basedir}/rpms

docker run \
    --rm \
    -v ${basedir}:/scripts \
    -v ${basedir}/rpms:/rpms \
    -e AWS_ACCESS_KEY \
    -e AWS_SECRET_KEY \
    -e BUCKET \
    -e REPO \
    -i -t \
    blalor/centos-buildtools:latest \
    /scripts/build_all.sh "$@"
