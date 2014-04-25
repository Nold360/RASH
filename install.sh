#!/bin/bash
####################################
# small installations script for RASH
# Gerrit 'nold' Pannek -- 2014
####################################

if [ $UID -ne 0 ] ; then
	echo "Should be root to do this.."
	exit 1
fi	

echo "Copy files..."
mkdir -p /var/lib/rash/shutdown.d/
cp -vr etc/rash /etc/
cp -v etc/init.d/* /etc/init.d/
cp -v usr/local/bin/* /usr/local/bin/  
chmod 755 /etc/rash/*
chown root: /etc/rash/* /etc/init.d/rash* /usr/local/bin/rash*


echo "Adding user..."
groupadd -g 1342 rashuser
useradd -s /bin/bash -g rashuser -d /var/lib/rash -m rashuser
mkdir -p /var/lib/rash/shutdown.d/
chown -R rashuser:rashuser /var/lib/rash/

echo "You should now exchange the keypairs... and configure /etc/rash/*"
exit 0
