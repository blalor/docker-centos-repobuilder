#!/bin/bash

## rpm preinstall script

set -e

## maybe create consul user and group
getent group consul >/dev/null || groupadd -r consul

getent passwd consul >/dev/null || \
    useradd \
        --system \
        --gid consul \
        --shell /sbin/nologin \
        --home-dir /var/lib/consul \
        --comment "Consul" \
        consul

exit 0
