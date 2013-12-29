#!/bin/bash

set -e
set -x

## Figuring out the full dependency tree and what's already available via yum is
## totally manual.  This script reflects that state, but there's probably a
## better way…

## supervisor requires meld3, available in epel repo
fpm -s python -t rpm -v 3.0 supervisor

## pip requires setuptools, available in base repo
fpm -s python -t rpm -v 1.4.1 pip
