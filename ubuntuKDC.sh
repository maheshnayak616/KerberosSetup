#!/bin/sh
# https://community.hortonworks.com/storage/attachments/7636-install-kdc-ubuntush.txt
# Install packages
echo "Installing Kerberos Packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y krb5-kdc krb5-admin-server krb5-user krb5-config rng-tools

service krb5-kdc start
service krb5-admin-server start

# #################################
# Assming default configuration!!!!
# #################################

# Create krb5.conf file
HOSTNAME=`hostname`
REALM="EXAMPLE.COM"
echo "Creating krb5.conf file, assuming KDC host is ${HOSTNAME} and realm is ${REALM}" 
cat >/etc/krb5.conf <<EOF
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 default_realm = ${REALM}
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true

[realms]
 ${REALM} = {
  kdc = ${HOSTNAME}
  admin_server = ${HOSTNAME}
 }

[domain_realm]
 .${HOSTNAME} = ${REALM}
 ${HOSTNAME} = ${REALM}
EOF

echo "Creating kdc.conf file, assuming realm is ${REALM}"
cat >/etc/krb5kdc/kadm5.acl <<EOF
*/admin@${REALM}	*
EOF

# Create KDC database
echo "Created KDC database, this could take some time"
echo "HRNGDEVICE=/dev/uransom" > /etc/default/rng-tools
/etc/init.d/rng-tools start
mkdir -p /etc/krb5kdc
kdb5_util create -s -P hadoop

# Create admistrative user
echo "Creating administriative account:"
echo "  principal:  admin/admin"
echo "  password:   hadoop"
kadmin.local -q 'addprinc -pw hadoop admin/admin'

update-rc.d krb5-kdc defaults
update-rc.d krb5-admin-server defaults

# Starting services
echo "Starting services"
service krb5-kdc start
service krb5-admin-server start

