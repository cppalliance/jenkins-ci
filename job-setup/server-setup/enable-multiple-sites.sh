#!/bin/bash

# set -xe

cd /etc/nginx/sites-available

for site in $(ls -1); do
    echo "site is $site"
    ln -s /etc/nginx/sites-available/$site /etc/nginx/sites-enabled/$site
done

