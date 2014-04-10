#!/bin/bash

set -e
set -x

. $( dirname $0 )/common

## Figuring out the full dependency tree and what's already available via yum is
## totally manual.  This script reflects that state, but there's probably a
## better way…

## supervisor requires meld3, available in epel repo
pkg_exists_in_repo python-supervisor-3.0 || fpm -s python -t rpm -v 3.0 supervisor

## pip requires setuptools, available in base repo
pkg_exists_in_repo python-pip-1.4.1 || fpm -s python -t rpm -v 1.4.1 pip

pkg_exists_in_repo python-twisted-11.1.0       || fpm -s python -t rpm Twisted==11.1.0
pkg_exists_in_repo python-zope.interface-4.0.5 || fpm -s python -t rpm -v 4.0.5 zope.interface
pkg_exists_in_repo python-txamqp-0.6.2         || fpm -s python -t rpm -v 0.6.2 txamqp

## --provides required by python-django-tagging, and for compatibility with
## python-Django package in EPEL
pkg_exists_in_repo python-django-1.3 || fpm -s python -t rpm --provides Django Django==1.3

graphite_ver="0.9.12"
pkg_exists_in_repo python-carbon-${graphite_ver}       || fpm -s python -t rpm -v ${graphite_ver} carbon
pkg_exists_in_repo python-whisper-${graphite_ver}      || fpm -s python -t rpm -v ${graphite_ver} whisper
pkg_exists_in_repo python-graphite-web-${graphite_ver} || fpm -s python -t rpm -v ${graphite_ver} graphite-web

## my docker-sync stuff
pkg_exists_in_repo python-docker-sync-1.0.2       || fpm -s python -t rpm -v 1.0.2  docker-sync
pkg_exists_in_repo python-pyyaml-3.11             || fpm -s python -t rpm -v 3.11   PyYAML
pkg_exists_in_repo python-docker-py-0.3.1         || fpm -s python -t rpm -v 0.3.1  docker-py
pkg_exists_in_repo python-websocket-client-0.11.0 || fpm -s python -t rpm -v 0.11.0 websocket-client
