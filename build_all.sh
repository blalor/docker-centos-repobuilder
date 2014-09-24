#!/bin/bash

[ -e /.dockerenv ] || {
    echo "not running in a Docker container!"
    exit 1
}

have_aws=0
if [ -n "${AWS_ACCESS_KEY}" ] && [ -n "${AWS_SECRET_KEY}" ] && [ -n "${BUCKET}" ] && [ -n "${REPO}" ] ; then
    have_aws=1
else
    echo "no AWS config; not syncing to S3"
fi

set -e

if [ $have_aws -eq 1 ]; then
    ## very old version of s3cmd in epel. :-(
    sed \
        -e "s#\$AWS_ACCESS_KEY#${AWS_ACCESS_KEY}#" \
        -e "s#\$AWS_SECRET_KEY#${AWS_SECRET_KEY}#" \
        < /scripts/config/s3.cfg \
        > /tmp/s3.cfg
fi

set -x

basedir=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
rpmsdir="/rpms"

mkdir -p ${rpmsdir}

if [ $have_aws -eq 1 ]; then
    ## pull from S3
    s3cmd -c /tmp/s3.cfg \
        sync \
        s3://${BUCKET}/${REPO}/ ${rpmsdir}/
fi

## run after sync so metadata is up to date with packages on filesystem
createrepo ${rpmsdir}

cd ${rpmsdir}

if [ $# -gt 0 ]; then
    builders="$@"
else
    builders=$( ls /scripts/builders/*.sh | sort )
fi

for builder in ${builders}; do
    ${builder}
done

## run again to generate metadata for new packages
createrepo ${rpmsdir}

if [ $have_aws -eq 1 ]; then
    ## push to S3
    s3cmd -c /tmp/s3.cfg \
        sync \
        --delete \
        --no-preserve \
        ${rpmsdir}/ s3://${BUCKET}/${REPO}/
fi
