#!/bin/bash

token=$(cat /etc/hetzner-dns-token)

subdomainCount=$(echo $CERTBOT_DOMAIN | grep -o "\." | wc -l)
subdomainCount=$((subdomainCount+1))

while [[ -z $zone_id && $subdomainCount -ge 2 ]];do

search_name=$( echo $CERTBOT_DOMAIN | rev | cut -d'.' -f 1-$subdomainCount | rev)
subdomainCount=$((subdomainCount-1))

zone_id=$(curl \
        -H "Auth-API-Token: ${token}" \
        "https://dns.hetzner.com/api/v1/zones?search_name=${search_name}" | \
        jq ".\"zones\"[] | select(.name == \"${search_name}\") | .id" 2>/dev/null | tr -d '"')

done

curl -X "POST" "https://dns.hetzner.com/api/v1/records" \
     -H 'Content-Type: application/json' \
     -H "Auth-API-Token: ${token}" \
     -d "{ \"value\": \"${CERTBOT_VALIDATION}\", \"ttl\": 300, \"type\": \"TXT\", \"name\": \"_acme-challenge.${CERTBOT_DOMAIN}.\", \"zone_id\": \"${zone_id}\" }" > /dev/null 2>/dev/null

# just make sure we sleep for a while (this should be a dig poll loop)
sleep 30
