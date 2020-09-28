#!/usr/bin/env bash

VAULT_URL=${VAULT_URL-http://vault:8200};

# [[ -z "$VAULT_TOKEN" ]] && echo "VAULT_TOKEN env var is required." && exit 1;

init() {
  keys_file=$1

  if [ ! -f "$keys_file" ]; then
    curl \
      --request PUT \
      --data '{"secret_shares": 10, "secret_threshold": 5}' \
      $VAULT_URL/v1/sys/init > $keys_file
  fi

  last_response=''

  for key in $(cat $keys_file | jq -r '.keys[]'); do
    last_response="$(curl \
      --request PUT \
      --data "{\"key\": \"$key\"}" \
      $VAULT_URL/v1/sys/unseal | jq -r '.sealed')"
  done

  if [ "$last_response" = "false" ]; then
    echo "Vault has been unsealed";
  fi
}

read_from_vault() {
  [[ -z "$VAULT_TOKEN" ]] && echo "VAULT_TOKEN env var is required." && exit 1;

  key=$1

  curl \
    -s \
    -X GET \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    -H "Content-Type: application/json" \
    $VAULT_URL/v1/cubbyhole/$key;
}

write_to_vault() {
  [[ -z "$VAULT_TOKEN" ]] && echo "VAULT_TOKEN env var is required." && exit 1;

  key=$1
  value=$2

  curl \
    -s \
    -X POST \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"value\": \"$value\"}" \
    $VAULT_URL/v1/cubbyhole/$key;
}
