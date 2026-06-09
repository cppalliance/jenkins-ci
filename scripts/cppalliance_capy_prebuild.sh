#!/bin/bash

set -xe
echo "export PRTEST=prtest3" >> jenkinsjobinfo.sh
sudo gem update asciidoctor
asciidoctor --version || true

