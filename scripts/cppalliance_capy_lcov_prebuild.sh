#!/bin/bash

set -xe
echo "export PRTEST=prtest3" >> jenkinsjobinfo.sh
echo "export B2_CXXSTD=20" >> jenkinsjobinfo.sh
echo "export GCOVR_BRANCH_COVERAGE=1" >> jenkinsjobinfo.sh
