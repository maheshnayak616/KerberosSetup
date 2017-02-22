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
export host=$(hostname -f)
export realm=${realm:-EXAMPLE.COM}
export domain=${domain:-example.com}
export kdcpassword=${kdcpassword:-BadPass#1}

echo "Creating krb5.conf file, assuming KDC host is ${host} and realm is ${realm}"
cat >/etc/krb5.conf <<EOF
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 default_realm = ${realm}
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true

[realms]
 ${realm} = {
  kdc = ${host}
  admin_server = ${host}
 }

[domain_realm]
 .${host} = ${realm}
 ${host} = ${realm}
EOF

echo "Creating kdc.conf file, assuming realm is ${realm}"
cat >/etc/krb5kdc/kadm5.acl <<EOF
*/admin@${realm}	*
EOF

echo $kdcpassword > passwd
echo $kdcpassword >> passwd

# Create KDC database
echo "Created KDC database, this could take some time"
echo "HRNGDEVICE=/dev/uransom" > /etc/default/rng-tools
/etc/init.d/rng-tools start
mkdir -p /etc/krb5kdc
kdb5_util create -s < passwd

# Create admistrative user
echo "Creating administriative account:"
echo "  principal:  admin/admin"
echo "  password:   $kdcpassword"
kadmin.local -q "addprinc admin/admin" < passwd
rm -f passwd

update-rc.d krb5-kdc defaults
update-rc.d krb5-admin-server defaults

# Starting services
echo "Starting services"
service krb5-kdc start
service krb5-admin-server start