#!/bin/bash

set -xe
echo "export PRTEST=prtest3" >> jenkinsjobinfo.sh
echo "export EXTRA_BOOST_LIBRARIES='cppalliance/buffers cppalliance/capy cppalliance/http'" >> jenkinsjobinfo.sh
echo "export B2_CXXSTD=20" >> jenkinsjobinfo.sh
