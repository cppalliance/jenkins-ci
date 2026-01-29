#!/bin/bash

set -xe
pwd
sourcefile=boost-root/libs/decimal/doc/html/decimal.html
destfile=boost-root/libs/decimal/doc/html/index.html

if [ ! -f $destfile ]; then
    cp $sourcefile $destfile
fi
