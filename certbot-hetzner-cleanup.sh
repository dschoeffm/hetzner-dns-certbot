#!/bin/bash

set -x

token=$(cat /etc/hetzner-dns-token)
search_name=$( echo $CERTBOT_DOMAIN | rev | cut -d'.' -f 1,2 | rev)

zone_id=$(curl \
        -H "Auth-API-Token: ${token}" \
        "https://dns.hetzner.com/api/v1/zones?search_name=${search_name}" | \
        jq ".\"zones\"[] | select(.name == \"${search_name}\") | .id" 2>/dev/null | tr -d '"')

record_ids=$(curl \
	-H "Auth-API-Token: $token" \
	"https://dns.hetzner.com/api/v1/records?zone_id=$zone_id" | \
       jq ".\"records\"[] | select(.name == \"_acme-challenge.${CERTBOT_DOMAIN}.\") | .id" 2>/dev/null | tr -d '"')

for record_id in $record_ids
do
	curl -H "Auth-API-Token: $token" \
		-X "DELETE" "https://dns.hetzner.com/api/v1/records/${record_id}" > /dev/null 2> /dev/null
done
