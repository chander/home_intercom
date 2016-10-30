#!/bin/bash
WDIR=$(dirname $0)
pushd $WDIR &> /dev/null
echo -n "Enter your hostname: "
read HOSTNAME
grep -i "$HOSTNAME" openssl.cnf &> /dev/null
if [[ $? != 0 ]]; then
  echo "Hostname not found in openssl.cnf, perhaps you need to replace ENTER_YOUR_FQDN_HERE with it?"
  exit 1
fi
FN_HOSTNAME=$(echo $HOSTNAME|sed 's/\./_/g')
echo $FN_HOSTNAME
openssl req -out ${FN_HOSTNAME}.csr -new -newkey rsa:2048 -nodes -keyout ${FN_HOSTNAME}.key -config openssl.cnf
openssl req -new -out ${FN_HOSTNAME}.csr -key ${FN_HOSTNAME}.key -config openssl.cnf
openssl req -text -noout -in ${FN_HOSTNAME}.csr  
popd &>/dev/null
