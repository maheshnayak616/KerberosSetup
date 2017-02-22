# https://gist.githubusercontent.com/abajwa-hw/f8b83e1c12abb1564531e00836b098fa/raw

export host=$(hostname -f)
export realm=${realm:-HORTONWORKS.COM}
export domain=${domain:-hortonworks.com}
export kdcpassword=${kdcpassword:-BadPass#1}

set -e

yum -y install krb5-server krb5-libs krb5-auth-dialog krb5-workstation

tee /var/lib/ambari-server/resources/scripts/krb5.conf > /dev/null << EOF
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 default_realm = $realm
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true

[realms]
 $realm = {
  kdc = $host
  admin_server = $host
 }

[domain_realm]
 .$domain = $realm
 domain = $realm
EOF

/bin/cp -f /var/lib/ambari-server/resources/scripts/krb5.conf /etc
 
echo $kdcpassword > passwd
echo $kdcpassword >> passwd
kdb5_util create -s < passwd


service krb5kdc start
service kadmin start
chkconfig krb5kdc on
chkconfig kadmin on

kadmin.local -q "addprinc admin/admin" < passwd
rm -f passwd


tee /var/kerberos/krb5kdc/kadm5.acl  > /dev/null << EOF
*/admin@$realm	 *
EOF

service krb5kdc restart
service kadmin restart

echo "Waiting to KDC to restart..."
sleep 10

service krb5kdc status
service kadmin status

#echo "Testing KDC..."
#kadmin -p admin/admin -w $kdcpassword -r $realm -q "get_principal admin/admin"

echo "KDC setup complete"
