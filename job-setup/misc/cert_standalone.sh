#!/bin/bash

set -e

website=$1

if [ -z "$website" ]; then
    echo "Please set website value. Exiting."
    exit 1
fi

echo " "
echo "STEP 1: Requesting cert"
echo " "

certbot certonly --webroot-path /var/www/letsencrypt --webroot -d $website

echo " "
echo "STEP 2 continued: MODIFYING RENEWAL FILE"
echo " "

renewalfile=/etc/letsencrypt/renewal/${website}.conf
if ! grep try-reload-or-restart $renewalfile ; then
   sed -i 's/\[renewalparams\]/[renewalparams]\nrenew_hook = systemctl try-reload-or-restart nginx/' $renewalfile
fi
