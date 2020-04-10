#/bin/bash

token=$(cat /etc/hetzner-dns-token)

zone_id=$(curl \
	-H "Auth-API-Token: ${token}" \
	"https://dns.hetzner.com/api/v1/zones" | \
	jq ".\"zones\"[] | select(.name == \"${CERTBOT_DOMAIN}\") | .id" 2>/dev/null | tr -d '"')

curl -X "POST" "https://dns.hetzner.com/api/v1/records" \
     -H 'Content-Type: application/json' \
     -H "Auth-API-Token: ${token}" \
     -d "{ \"value\": \"${CERTBOT_VALIDATION}\", \"ttl\": 86400, \"type\": \"TXT\", \"name\": \"_acme-challenge\", \"zone_id\": \"${zone_id}\" }" > /dev/null 2>/dev/null

# just make sure we sleep for a while (this should be a dig poll loop)
sleep 30
