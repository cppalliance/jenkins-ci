#!/bin/bash

set -xe
echo "Using sudo"
echo "export PRTEST=prtest3" >> jenkinsjobinfo.sh
# Added to container
# sudo apt-get update
# sudo apt-get install -y openssl libssl-dev

# How to make this more durable for future clang?
# Or, URL has already been updated.
echo "export CXX=/usr/bin/clang++-18" >> jenkinsjobinfo.sh
echo "export CC=/usr/bin/clang-18" >> jenkinsjobinfo.sh
# buffers may not be required
echo "export EXTRA_BOOST_LIBRARIES='cppalliance/buffers cppalliance/http_proto cppalliance/capy'" >> jenkinsjobinfo.sh

