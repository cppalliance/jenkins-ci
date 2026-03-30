#!/bin/bash

# Prepare pull request preview jobs.

# It's not necessary to add a dns entry, since there is a wildcard dns entry *.prtestexperiment4.cppalliance.org.

set -xe

# According to earlier notes, this step was done. Move all the previous prtest files and dirs out of the way.

rm -rf /etc/letsencrypt/renewal/prtestexperiment.cppalliance.org.conf
rm -rf /etc/letsencrypt/live/prtestexperiment.cppalliance.org/
rm -rf /etc/letsencrypt/archive/prtestexperiment.cppalliance.org/

rm -rf /etc/letsencrypt/renewal/prtestexperiment1.cppalliance.org.conf
rm -rf /etc/letsencrypt/live/prtestexperiment1.cppalliance.org/
rm -rf /etc/letsencrypt/archive/prtestexperiment1.cppalliance.org/
rm -rf /etc/letsencrypt/renewal/prtestexperiment2.cppalliance.org.conf
rm -rf /etc/letsencrypt/live/prtestexperiment2.cppalliance.org/
rm -rf /etc/letsencrypt/archive/prtestexperiment2.cppalliance.org/
rm -rf /etc/letsencrypt/renewal/prtestexperiment3.cppalliance.org.conf
rm -rf /etc/letsencrypt/live/prtestexperiment3.cppalliance.org/
rm -rf /etc/letsencrypt/archive/prtestexperiment3.cppalliance.org/
rm -rf /etc/letsencrypt/renewal/prtestexperiment4.cppalliance.org.conf
rm -rf /etc/letsencrypt/live/prtestexperiment4.cppalliance.org/
rm -rf /etc/letsencrypt/archive/prtestexperiment4.cppalliance.org/
rm -rf /etc/letsencrypt/renewal/prtestexperiment5.cppalliance.org.conf
rm -rf /etc/letsencrypt/live/prtestexperiment5.cppalliance.org/
rm -rf /etc/letsencrypt/archive/prtestexperiment5.cppalliance.org/

exit 0
certbot certonly --dns-cloudflare --dns-cloudflare-propagation-seconds 10 --dns-cloudflare-credentials /etc/letsencrypt/.secret \
-d *.prtestexperiment5.cppalliance.org \
-d *.boostbook.prtestexperiment5.cppalliance.org \
-d *.boostlook2.prtestexperiment5.cppalliance.org \
-d *.boostlook3.prtestexperiment5.cppalliance.org \
-d *.boostlook4.prtestexperiment5.cppalliance.org \
-d *.boostlook5.prtestexperiment5.cppalliance.org \
-d *.boostlook6.prtestexperiment5.cppalliance.org \
-d *.boostlook7.prtestexperiment5.cppalliance.org \
-d *.boostlook8.prtestexperiment5.cppalliance.org \
-d *.boostlook9.prtestexperiment5.cppalliance.org \
-d *.boostlook10.prtestexperiment5.cppalliance.org \
-d *.boostlook11.prtestexperiment5.cppalliance.org \
-d *.boostlook12.prtestexperiment5.cppalliance.org \
-d *.boostlook13.prtestexperiment5.cppalliance.org \
-d *.boostlook14.prtestexperiment5.cppalliance.org \
-d *.boostlook15.prtestexperiment5.cppalliance.org \
-d *.boostlook16.prtestexperiment5.cppalliance.org \
-d *.boostlook17.prtestexperiment5.cppalliance.org \
-d *.boostlook18.prtestexperiment5.cppalliance.org \
-d *.boostlook19.prtestexperiment5.cppalliance.org \
-d *.boostlook20.prtestexperiment5.cppalliance.org \
-d *.boostlook21.prtestexperiment5.cppalliance.org \
-d *.boostlook22.prtestexperiment5.cppalliance.org \
-d *.boostlook23.prtestexperiment5.cppalliance.org \
-d *.boostlook24.prtestexperiment5.cppalliance.org \
-d *.boostlook25.prtestexperiment5.cppalliance.org \
-d *.boostlook26.prtestexperiment5.cppalliance.org \
-d *.boostlook27.prtestexperiment5.cppalliance.org \
-d *.boostlook28.prtestexperiment5.cppalliance.org \
-d *.boostlook29.prtestexperiment5.cppalliance.org \
-d *.boostlook30.prtestexperiment5.cppalliance.org \
-d *.boostlook31.prtestexperiment5.cppalliance.org \
-d *.boostlook32.prtestexperiment5.cppalliance.org \
-d *.boostlook33.prtestexperiment5.cppalliance.org \
-d *.boostlook34.prtestexperiment5.cppalliance.org \
-d *.boostlook35.prtestexperiment5.cppalliance.org \
-d *.boostlook36.prtestexperiment5.cppalliance.org \
-d *.boostlook37.prtestexperiment5.cppalliance.org \
-d *.boostlook38.prtestexperiment5.cppalliance.org \
-d *.boostlook39.prtestexperiment5.cppalliance.org \
-d *.boostlook40.prtestexperiment5.cppalliance.org \
-d *.boostlook41.prtestexperiment5.cppalliance.org \
-d *.boostlook42.prtestexperiment5.cppalliance.org \
-d *.boostlook43.prtestexperiment5.cppalliance.org \
-d *.boostlook44.prtestexperiment5.cppalliance.org \
-d *.boostlook45.prtestexperiment5.cppalliance.org \
-d *.boostlook46.prtestexperiment5.cppalliance.org \
-d *.boostlook47.prtestexperiment5.cppalliance.org \
-d *.boostlook48.prtestexperiment5.cppalliance.org \
-d *.boostlook49.prtestexperiment5.cppalliance.org \
-d *.boostlook50.prtestexperiment5.cppalliance.org \
-d *.boostlook51.prtestexperiment5.cppalliance.org \
-d *.boostlook52.prtestexperiment5.cppalliance.org \
-d *.boostlook53.prtestexperiment5.cppalliance.org \
-d *.boostlook54.prtestexperiment5.cppalliance.org \
-d *.boostlook55.prtestexperiment5.cppalliance.org \
-d *.boostlook56.prtestexperiment5.cppalliance.org \
-d *.boostlook57.prtestexperiment5.cppalliance.org \
-d *.boostlook58.prtestexperiment5.cppalliance.org \
-d *.boostlook59.prtestexperiment5.cppalliance.org \
-d *.boostlook90.prtestexperiment5.cppalliance.org \
-d *.boostlook91.prtestexperiment5.cppalliance.org \
-d *.boostlook92.prtestexperiment5.cppalliance.org \
-d *.boostlook93.prtestexperiment5.cppalliance.org \
-d *.boostlook94.prtestexperiment5.cppalliance.org \
-d *.boostlook95.prtestexperiment5.cppalliance.org \
-d *.boostlook96.prtestexperiment5.cppalliance.org \
-d *.boostlook97.prtestexperiment5.cppalliance.org \
-d *.boostlook98.prtestexperiment5.cppalliance.org \
-d *.boostlook99.prtestexperiment5.cppalliance.org \
-d *.boostlook60.prtestexperiment5.cppalliance.org \
-d *.boostlook61.prtestexperiment5.cppalliance.org \
-d *.boostlook62.prtestexperiment5.cppalliance.org \
-d *.boostlook63.prtestexperiment5.cppalliance.org \
-d *.boostlook64.prtestexperiment5.cppalliance.org \
-d *.boostlook65.prtestexperiment5.cppalliance.org \
-d *.boostlook66.prtestexperiment5.cppalliance.org \
-d *.boostlook67.prtestexperiment5.cppalliance.org \
-d *.boostlook68.prtestexperiment5.cppalliance.org \
-d *.boostlook69.prtestexperiment5.cppalliance.org \
-d *.boostlook80.prtestexperiment5.cppalliance.org \
-d *.boostlook81.prtestexperiment5.cppalliance.org \
-d *.boostlook82.prtestexperiment5.cppalliance.org \
-d *.boostlook83.prtestexperiment5.cppalliance.org \
-d *.boostlook84.prtestexperiment5.cppalliance.org \
-d *.boostlook85.prtestexperiment5.cppalliance.org \
-d *.boostlook86.prtestexperiment5.cppalliance.org \
-d *.boostlook87.prtestexperiment5.cppalliance.org \
-d *.boostlook88.prtestexperiment5.cppalliance.org \
-d *.boostlook89.prtestexperiment5.cppalliance.org \
-d *.boostlook110.prtestexperiment5.cppalliance.org \
-d *.boostlook111.prtestexperiment5.cppalliance.org \
-d *.boostlook112.prtestexperiment5.cppalliance.org \
-d *.boostlook113.prtestexperiment5.cppalliance.org \
-d *.boostlook114.prtestexperiment5.cppalliance.org \
-d *.boostlook115.prtestexperiment5.cppalliance.org \
-d *.boostlook116.prtestexperiment5.cppalliance.org \
-d *.boostlook117.prtestexperiment5.cppalliance.org \
-d *.boostlook118.prtestexperiment5.cppalliance.org \
-d *.boostlook119.prtestexperiment5.cppalliance.org \


# systemctl restart nginx

# 5 propagation-seconds and 16 domains total, it failed, 15 out of 16 TXT records missing.
# (continue again) 10 propagation-seconds and 16 domains total, it passed.
# 10 propagation-seconds and 36 domains total, it failed, 4 out of 36 TXT records missing.
# (continue again) 10 propagation-seconds and 46 domains total, it passed. 
# 10 propagation-seconds and 46 domains total, it failed. 12 out of 46 TXT records missing.


