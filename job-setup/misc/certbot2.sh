#!/bin/bash

# Originally there were shared certs. One for prtest. Another on prtest2.
# The problem was it seemed to hit a limit after 15 or 20 certs.
# Individual separate certs are more maintainable, switch to prtest3.
# So certbot.sh and certbot2.sh are mostly deprecated. But those certs
# are still in use.

# Prepare pull request preview jobs.

# It's not necessary to add a dns entry, since there is a wildcard dns entry *.prtest2.cppalliance.org.

set -xe

mkdir -p /etc/bcks
export timestamp=$(date -u +'%Y-%m-%d-%H-%M-%S')
rsync -ahv /etc/letsencrypt /etc/bcks/letsencrypt.$timestamp

# According to earlier notes, this step was done. Move all the previous prtest files and dirs out of the way.

rm -rf /etc/letsencrypt/renewal/prtest2.cppalliance.org.conf
rm -rf /etc/letsencrypt/live/prtest2.cppalliance.org/
rm -rf /etc/letsencrypt/archive/prtest2.cppalliance.org/

certbot certonly --dns-cloudflare --dns-cloudflare-propagation-seconds 20 --dns-cloudflare-credentials /etc/letsencrypt/.secret \
-d *.prtest2.cppalliance.org \
-d *.boostbook.prtest2.cppalliance.org \
-d *.boostlook.prtest2.cppalliance.org \
-d *.buffersantora.prtest2.cppalliance.org \
-d *.crypt.prtest2.cppalliance.org \
-d *.http-io.prtest2.cppalliance.org \
-d *.json.prtest2.cppalliance.org \
-d *.mrdocs.prtest2.cppalliance.org \
-d *.mrdox.prtest2.cppalliance.org \
-d *.site-docs.prtest2.cppalliance.org \
-d *.safe-cpp.prtest2.cppalliance.org \
-d *.unordered.prtest2.cppalliance.org \
-d *.url.prtest2.cppalliance.org \
-d *.urlantora.prtest2.cppalliance.org \
-d *.utility.prtest2.cppalliance.org \
-d *.vinniefalco.prtest2.cppalliance.org \


systemctl restart nginx
