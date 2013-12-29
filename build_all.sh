#!/bin/bash

set -e
set -x

basedir="$( dirname $0 )"
rpmsdir="/rpms"

yum -y install s3cmd

cd ${rpmsdir}

for builder in /scripts/builders/*; do
    ${builder}
done

createrepo ${rpmsdir}

set +x ## don't echo keys :-)

## very old version of s3cmd in epel. :-(
sed \
    -e "s#\$AWS_ACCESS_KEY#${AWS_ACCESS_KEY}#" \
    -e "s#\$AWS_SECRET_KEY#${AWS_SECRET_KEY}#" \
    < /scripts/config/s3.cfg \
    > /tmp/s3.cfg

s3cmd -c /tmp/s3.cfg \
    sync \
    --delete \
    --no-preserve \
    ${rpmsdir}/ s3://${BUCKET}/${REPO}/
