#!/bin/bash

set -xe
echo "export PRTEST=prtest2" >> jenkinsjobinfo.sh
echo "export ONLY_BUILD_ON_DOCS_MODIFICATION=true" >> jenkinsjobinfo.sh
