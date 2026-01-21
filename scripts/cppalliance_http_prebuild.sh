#!/bin/bash

set -xe
echo "export PRTEST=prtest3" >> jenkinsjobinfo.sh
# buffers may not be required
echo "export EXTRA_BOOST_LIBRARIES='cppalliance/buffers cppalliance/capy cppalliance/corosio'" >> jenkinsjobinfo.sh
