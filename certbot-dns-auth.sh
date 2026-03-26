#!/bin/bash
DOMAIN="_acme-challenge.$CERTBOT_DOMAIN"
VALUE="$CERTBOT_VALIDATION"
aliyun alidns AddDomainRecord --DomainName shunshiapp.com --RR "_acme-challenge.$CERTBOT_DOMAIN" --Type TXT --Value "$VALUE" 2>/dev/null
sleep 5
