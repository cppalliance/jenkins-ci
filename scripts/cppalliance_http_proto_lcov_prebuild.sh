#!/bin/bash

set -xe
echo "export PRTEST=prtest" >> jenkinsjobinfo.sh
echo "export EXTRA_BOOST_LIBRARIES='cppalliance/buffers cppalliance/capy'" >> jenkinsjobinfo.sh
