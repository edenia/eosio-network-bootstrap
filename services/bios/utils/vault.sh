#!/usr/bin/env bash

set -e;

VAULT_URL=${VAULT_URL-http://vault:8200};

# [[ -z "$VAULT_TOKEN" ]] && echo "VAULT_TOKEN env var is required." && exit 1;

vault=$"curl \
  -H 'X-Vault-Token: $VAULT_TOKEN' \
  $VAULT_URL/v1/secret/";

read_from_vault() {
  key=$1
  $vault/$key \
    -X GET;
}

write_to_vault() {
  key=$1
  value=$2

  $vault/$key \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{"value": "$value"}';
}
