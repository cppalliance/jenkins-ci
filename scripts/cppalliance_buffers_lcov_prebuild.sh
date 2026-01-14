#!/bin/bash

set -xe
echo "export EXTRA_BOOST_LIBRARIES='cppalliance/capy'" >> jenkinsjobinfo.sh
echo "export PRTEST=prtest" >> jenkinsjobinfo.sh
echo "export B2_CXXSTD=20" >> jenkinsjobinfo.sh
