#!/bin/bash
set -xe

if [ -d "/opt/nvm" ]; then
    export NVM_DIR=/opt/nvm
    echo "Use shared nvm installation"
else
    export NVM_DIR=$HOME/.nvm_${REPONAME}_antora
    echo "Use home dir nvm installation"
fi
mkdir -p "$NVM_DIR"
export NODE_VERSION=18.18.1
# The container has a pre-installed nodejs. Overwrite those again.
export NVM_BIN="$NVM_DIR/versions/node/v${NODE_VERSION}/bin"
export NVM_INC=$NVM_DIR/versions/node/v${NODE_VERSION}/include/node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
export PATH="$NVM_DIR/versions/node/v${NODE_VERSION}/bin/:${PATH}"
node --version
npm --version
npm install gulp-cli@2.3.0
npm install @mermaid-js/mermaid-cli@10.5.1

# 2025-01-25
cd docs/ui
npm ci
npx gulp lint
npx gulp
cd ../..

cd docs
npm ci

# While official docs may use "npx antora antora-playbook.yml", it seems that fetches from develop or master.
# In the case of PRs, the local version should be used instead.
# npx antora local-antora-playbook.yml
# npx antora --log-level debug antora-playbook.yml --attribute branchesarray=HEAD
npx antora antora-playbook.yml --attribute branchesarray=HEAD
