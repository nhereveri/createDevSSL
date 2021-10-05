#!/bin/bash

MAX_DAYS=1000

RUTA=$(pwd|sed 's/\//\\\//g')
sed "s/#PASSWD#/${RUTA}/" config.template > config.cnf
mkdir -p certs crl newcerts private csr
touch index.txt
if [ ! -f serial ]
then
  echo 1000 | tee serial > /dev/null
fi
openssl genrsa -out private/ca.key.pem 4096
openssl req -config config.cnf -key private/ca.key.pem -new -x509 -days ${MAX_DAYS} -sha256 -extensions v3_ca -out certs/ca.cert.pem
openssl x509 -noout -text -in certs/ca.cert.pem
echo -e "\nRUN THIS COMMAND TO ADD CA Certificate to Keychain:\n\nsudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain certs/ca.cert.pem\n"
rm -f config.cnf
