#!/bin/bash

set -xe

rm -rf /etc/letsencrypt/renewal/prtest2.cppalliance.org.conf
rm -rf /etc/letsencrypt/live/prtest2.cppalliance.org/
rm -rf /etc/letsencrypt/archive/prtest2.cppalliance.org/

MAINDIR="/etc/letsencrypt"
BACKUPDIR="/etc/bcks/letsencrypt.2024-04-23-20-24-39/letsencrypt"

cd $BACKUPDIR
cd renewal
cp prtest2.cppalliance.org.conf $MAINDIR/renewal/
cd ..
cd live
cp -rp prtest2.cppalliance.org $MAINDIR/live/
cd ..
cd archive
cp -rp prtest2.cppalliance.org $MAINDIR/archive/

