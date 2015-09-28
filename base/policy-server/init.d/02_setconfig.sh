#!/bin/bash

echo "[*] Set configuration files: starting"

#may be needed for adv auth
fromfile="/opt/CA/siteminder/arcot/conf/adaptershim.ini"
tofile="/opt/CA/siteminder/config/adaptershim.ini"
#mv "$fromfile" "$tofile"

mv "/opt/CA/siteminder/lib/libsmaps_rename4aps.so" "/opt/CA/siteminder/lib/libsmaps.so"

mkdir -p /opt/CA/siteminder/bin/Mail
cp -r /opt/CA/siteminder/samples/APS_Mail_Files/* /opt/CA/siteminder/bin/Mail/

echo "[*] Set configuration files: complete"
