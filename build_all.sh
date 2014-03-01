#!/bin/bash

[ -e /.dockerenv ] || {
    echo "not running in a Docker container!"
    exit 1
}

set -e

## very old version of s3cmd in epel. :-(
sed \
    -e "s#\$AWS_ACCESS_KEY#${AWS_ACCESS_KEY}#" \
    -e "s#\$AWS_SECRET_KEY#${AWS_SECRET_KEY}#" \
    < /scripts/config/s3.cfg \
    > /tmp/s3.cfg

set -x

basedir="$( dirname $0 )"
rpmsdir="/rpms"

yum -y install s3cmd yum-utils

## pull from S3
s3cmd -c /tmp/s3.cfg \
    sync \
    s3://${BUCKET}/${REPO}/ ${rpmsdir}/

## run after sync so metadata is up to date with packages on filesystem
createrepo ${rpmsdir}

cd ${rpmsdir}

for builder in $( ls /scripts/builders/*.sh | sort ); do
    ${builder}
done

## run again to generate metadata for new packages
createrepo ${rpmsdir}

## push to S3
s3cmd -c /tmp/s3.cfg \
    sync \
    --delete \
    --no-preserve \
    ${rpmsdir}/ s3://${BUCKET}/${REPO}/
