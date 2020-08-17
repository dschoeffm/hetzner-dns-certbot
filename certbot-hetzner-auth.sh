#!/bin/bash

token=$(cat /etc/hetzner-dns-token)

zone_id=$(curl \
	-H "Auth-API-Token: ${token}" \
	"https://dns.hetzner.com/api/v1/zones?search_name=${CERTBOT_DOMAIN}" | \
	jq ".\"zones\"[] | select(.name == \"${CERTBOT_DOMAIN}\") | .id" 2>/dev/null | tr -d '"')

curl -X "POST" "https://dns.hetzner.com/api/v1/records" \
     -H 'Content-Type: application/json' \
     -H "Auth-API-Token: ${token}" \
     -d "{ \"value\": \"${CERTBOT_VALIDATION}\", \"ttl\": 86400, \"type\": \"TXT\", \"name\": \"_acme-challenge\", \"zone_id\": \"${zone_id}\" }" > /dev/null 2>/dev/null


POLLING_DNS=`dig +short NS ${CERTBOT_DOMAIN} | awk 'NR==1' | sed 's/.$//'`
POLLING_INTERVAL=2
POLLING_TIMEOUT=100
echo "Waiting for TXT record _acme-challenge.${CERTBOT_DOMAIN} with value \"${CERTBOT_VALIDATION}\" in NS ${POLLING_DNS}..."
i=0
until dig @${POLLING_DNS} -t txt _acme-challenge.${CERTBOT_DOMAIN} | grep ${CERTBOT_VALIDATION}
do
  ((i=i+POLLING_INTERVAL))
  if [[ $i -gt $POLLING_TIMEOUT ]]; then
    echo "Timed out waiting for TXT record" 1>&2;
    exit 1
  fi
	sleep $POLLING_INTERVAL
done
