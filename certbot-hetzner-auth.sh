#!/bin/bash

token=$(cat /etc/hetzner-dns-token)
search_name=$( echo $CERTBOT_DOMAIN | rev | cut -d'.' -f 1,2 | rev)

zone_id=$(curl \
	-H "Auth-API-Token: ${token}" \
	"https://dns.hetzner.com/api/v1/zones?search_name=${search_name}" | \
	jq ".\"zones\"[] | select(.name == \"${search_name}\") | .id" 2>/dev/null | tr -d '"')

curl -X "POST" "https://dns.hetzner.com/api/v1/records" \
     -H 'Content-Type: application/json' \
     -H "Auth-API-Token: ${token}" \
     -d "{ \"value\": \"${CERTBOT_VALIDATION}\", \"ttl\": 300, \"type\": \"TXT\", \"name\": \"_acme-challenge.${CERTBOT_DOMAIN}.\", \"zone_id\": \"${zone_id}\" }" > /dev/null 2>/dev/null

# just make sure we sleep for a while (this should be a dig poll loop)
sleep 30
