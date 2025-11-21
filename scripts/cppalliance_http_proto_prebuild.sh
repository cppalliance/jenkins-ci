#!/bin/bash

set -xe
echo "export PRTEST=prtest" >> jenkinsjobinfo.sh
# buffers may not be required
echo "export EXTRA_BOOST_LIBRARIES='cppalliance/buffers cppalliance/capy'" >> jenkinsjobinfo.sh
