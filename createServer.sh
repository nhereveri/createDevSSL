#!/bin/bash

MAX_DAYS=397

if [ $# -lt 1 ]
then
  echo "Missing parameter hostname"
  exit 1
fi

RUTA=$(pwd|sed 's/\//\\\//g')
sed "s/#PASSWD#/${RUTA}/" config.template > config.cnf

COUNT=2
for domain in $*
do
  echo "DNS.${COUNT} = ${domain}" >> config.cnf
  COUNT=$(( ${COUNT} + 1 ))
done

mkdir -p certs crl newcerts private csr
openssl genrsa -out "private/${1}.key.pem" 2048
openssl req -config config.cnf -key "private/${1}.key.pem" -new -sha256 -out "csr/${1}.csr.pem"
openssl ca -config config.cnf -extensions server_cert -days ${MAX_DAYS} -notext -md sha256 -in "csr/${1}.csr.pem" -out "certs/${1}.cert.pem"
openssl x509 -noout -text -in "certs/${1}.cert.pem"
openssl verify -CAfile certs/ca.cert.pem "certs/${1}.cert.pem"
cp "certs/${1}.cert.pem" "${1}.crt"
cp "private/${1}.key.pem" "${1}.key"
tar zcvf "${1}.tgz" "${1}.crt" "${1}.key"
rm -f "${1}.crt" "${1}.key" config.cnf
cat <<EOF
Use this lines in your apache config:

# this configuration requires mod_ssl, mod_rewrite, and mod_headers
<VirtualHost *:80>
    ServerName ${1}
    RewriteEngine On
    RewriteCond %{REQUEST_URI} !^/\.well\-known/acme\-challenge/
    RewriteRule ^(.*)\$ https://%{HTTP_HOST}\$1 [R=301,L]
</VirtualHost>

<VirtualHost *:443>
    ServerName ${1}

    SSLEngine on

    SSLCertificateFile      /path/to/ssl/${1}.crt
    SSLCertificateKeyFile   /path/to/ssl/${1}.key

    # enable HTTP/2, if available
    Protocols h2 http/1.1

    # HTTP Strict Transport Security (mod_headers is required) (63072000 seconds)
    Header always set Strict-Transport-Security "max-age=63072000"
</VirtualHost>

# Modern configuration
SSLProtocol             all -SSLv3 -TLSv1 -TLSv1.1 -TLSv1.2
SSLHonorCipherOrder     off
SSLSessionTickets       off

EOF
