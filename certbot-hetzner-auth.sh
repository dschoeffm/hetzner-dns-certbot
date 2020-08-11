#/bin/bash

token=$(cat /etc/hetzner-dns-token)

zone_id=$(curl \
	-H "Auth-API-Token: ${token}" \
	"https://dns.hetzner.com/api/v1/zones?search_name=${CERTBOT_DOMAIN}" | \
	jq ".\"zones\"[] | select(.name == \"${CERTBOT_DOMAIN}\") | .id" 2>/dev/null | tr -d '"')

curl -X "POST" "https://dns.hetzner.com/api/v1/records" \
     -H 'Content-Type: application/json' \
     -H "Auth-API-Token: ${token}" \
     -d "{ \"value\": \"${CERTBOT_VALIDATION}\", \"ttl\": 86400, \"type\": \"TXT\", \"name\": \"_acme-challenge\", \"zone_id\": \"${zone_id}\" }" > /dev/null 2>/dev/null

until dig @8.8.8.8 -t txt _acme-challenge.${CERTBOT_DOMAIN} | grep ${CERTBOT_VALIDATION}
do
	sleep 2
done
