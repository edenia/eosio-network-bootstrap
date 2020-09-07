#!/usr/bin/env bash

set -e;

EOSIO_OLD_CONTRACTS_DIRECTORY=/opt/old-eosio.contracts/build/contracts
EOSIO_CONTRACTS_DIRECTORY=/opt/eosio.contracts/build/contracts

store_secret_on_vault() {
  echo "Unimplemented feature, waiting for vault to store secrets in"
}

unlock_wallet() {
  cleos wallet unlock --password $(cat /opt/application/secrets/wallet_password.txt) \
    || echo "Wallet has already been unlocked..."
}

create_wallet() {
  mkdir -p /opt/application/secrets
  cleos wallet create --to-console \
    | awk 'FNR > 3 { print $1 }' \
    | tr -d '"' \
    > /opt/application/secrets/wallet_password.txt;
  cleos wallet open;
  unlock_wallet
  cleos wallet import --private-key $EOS_PRIV_KEY;
}

create_system_accounts() {
  system_accounts=( \
    "eosio.msig" \
    "eosio.token" \
  )

  for account in "${system_accounts[@]}"; do
    echo "Creating $account account..."

    keys=($(cleos create key --to-console))
    pub=${keys[5]}
    priv=${keys[2]}

    cleos wallet import --private-key $priv

    cleos create account eosio $account $pub;
  done

  echo "Creating writer account..."
  cleos push action eosio newaccount \
  '{
      "creator" : "eosio", 
      "name" : "writer",
      "active" : {
          "threshold":1,
          "keys":[],
          "accounts":[{"weight":1, "permission" :{"actor":"eosio", "permission":"active"}}],
          "waits":[]
      },
      "owner" : {
          "threshold":1,
          "keys":[],
          "accounts":[{"weight":1, "permission":{"actor":"eosio", "permission":"active"}}],
          "waits":[]
      }
  }' -p eosio

  echo 'Create access permission'

  cleos set account permission writer access \
  '{
      "threshold":1,
      "keys":[],
      "accounts":[{"weight":1, "permission" :{"actor":"eosio", "permission":"active"}}],
      "waits":[]
  }' owner -p writer@owner
}

activate_features() {
  # GET_SENDER
  cleos push action eosio activate '["f0af56d2c5a48d60a4a5b5c903edfb7db3a736a94ed589d0b797df33ff9d3e1d"]' -p eosio

  # FORWARD_SETCODE
  cleos push action eosio activate '["2652f5f96006294109b3dd0bbde63693f55324af452b799ee137a81a905eed25"]' -p eosio

  # ONLY_BILL_FIRST_AUTHORIZER
  cleos push action eosio activate '["8ba52fe7a3956c5cd3a656a3174b931d3bb2abb45578befc59f283ecd816a405"]' -p eosio

  # RESTRICT_ACTION_TO_SELF
  cleos push action eosio activate '["ad9e3d8f650687709fd68f4b90b41f7d825a365b02c23a636cef88ac2ac00c43"]' -p eosio

  # DISALLOW_EMPTY_PRODUCER_SCHEDULE
  cleos push action eosio activate '["68dcaa34c0517d19666e6b33add67351d8c5f69e999ca1e37931bc410a297428"]' -p eosio

  # FIX_LINKAUTH_RESTRICTION
  cleos push action eosio activate '["e0fb64b1085cc5538970158d05a009c24e276fb94e1a0bf6a528b48fbc4ff526"]' -p eosio

  # REPLACE_DEFERRED
  cleos push action eosio activate '["ef43112c6543b88db2283a2e077278c315ae2c84719a8b25f25cc88565fbea99"]' -p eosio

  # NO_DUPLICATE_DEFERRED_ID
  cleos push action eosio activate '["4a90c00d55454dc5b059055ca213579c6ea856967712a56017487886a4d4cc0f"]' -p eosio

  # ONLY_LINK_TO_EXISTING_PERMISSION
  cleos push action eosio activate '["1a99a59d87e06e09ec5b028a9cbb7749b4a5ad8819004365d02dc4379a8b7241"]' -p eosio

  # RAM_RESTRICTIONS
  cleos push action eosio activate '["4e7bf348da00a945489b2a681749eb56f5de00b900014e137ddae39f48f69d67"]' -p eosio

  # WEBAUTHN_KEY
  cleos push action eosio activate '["4fca8bd82bbd181e714e283f83e1b45d95ca5af40fb89ad3977b653c448f78c2"]' -p eosio

  # WTMSIG_BLOCK_SIGNATURES
  cleos push action eosio activate '["299dcb6af692324b899b39f16d5a530a33062804e41f09dc97e9f156b4476707"]' -p eosio

  sleep 2;
}

deploy_system_contracts() {
  cleos set contract eosio.token $EOSIO_CONTRACTS_DIRECTORY/eosio.token/
  sleep 2;

  cleos set contract eosio.msig $EOSIO_CONTRACTS_DIRECTORY/eosio.msig/
  sleep 2;

  curl --request POST \
    --url http://127.0.0.1:8888/v1/producer/schedule_protocol_feature_activations \
    -d '{"protocol_features_to_activate": ["0ec7e080177b2c02b278d5088611686b49d739925a92d9bfcacd7fc6b74053bd"]}'
  sleep 2;

  result=1
  set +e;
  while [ "$result" -ne "0" ]; do
    echo "Setting old eosio.bios contract...";
    cleos set contract eosio \
      $EOSIO_OLD_CONTRACTS_DIRECTORY/eosio.bios/ \
      -x 1000;
    result=$?
    [[ "$result" -ne "0" ]] && echo "Failed, trying again";
  done
  set -e;

  activate_features

  echo 'Set 0 resources to writer account (unusable)'
  cleos push action eosio setalimits '["writer", -1, 0, 0, 0]' -p eosio

  set +e;
  result=1;
  while [ "$result" -ne "0" ]; do
    echo "Setting LAC-Chain system contract...";
    cleos set contract eosio \
      $EOSIO_CONTRACTS_DIRECTORY/lacchain.system/ \
      -p eosio \
      -x 1000;
    result=$?
    [[ "$result" -ne "0" ]] && echo "Failed, trying again";
  done
  set -e;
}

set_msig_privileged_account() {
  cleos push action eosio setpriv \
    '["eosio.msig", 1]' -p eosio@active
}

set_lacchain_permissioning() {
  
  echo 'Create BIOS Partner Account'

  keys=($(cleos create key --to-console))
  pub=${keys[5]}
  priv=${keys[2]}

  echo 'secret' $priv

  cleos wallet import --private-key $priv

  echo 'Create Partner Entity'
  cleos push action eosio addentity '["latamlink", 1, '$pub']' -p eosio@active

  echo 'Get Partner Entity Account'
  cleos get account latamlink

  echo 'Inspect entity Table'
  cleos get table eosio eosio node

  #echo 'Set Entity Info'
  #entity_info="$(jq -r '.' $WORK_DIR/utils/entity.json)"
  #cleos push action eosio setentinfo '["latamlink", "'$entity_info'"]' -p latamlink@active

  echo 'Register Validator Nodes'
  # NOTE: Was not able to add as permissioning commitee
  cleos push action eosio addvalidator \
  '{
    "entity": "latamlink",
    "name": "validator1",
    "validator_authority": [
      "block_signing_authority_v0",
      {
        "threshold": 1,
        "keys": [{
          "key": "EOS5hLiffucJGRBfHACDGMa4h2gc5t43hJC3mJq5NqN9BfArhEcva",
          "weight": 1
        }]
      }
    ]
  }' -p latamlink@active

  '{
    "entity": "latamlink",
    "name": "validator2",
    "validator_authority": [
      "block_signing_authority_v0",
      {
        "threshold": 1,
        "keys": [{
          "key": "EOS5hLiffucJGRBfHACDGMa4h2gc5t43hJC3mJq5NqN9BfArhEcva",
          "weight": 1
        }]
      }
    ]
  }' -p latamlink@active

  '{
    "entity": "latamlink",
    "name": "validator3",
    "validator_authority": [
      "block_signing_authority_v0",
      {
        "threshold": 1,
        "keys": [{
          "key": "EOS5hLiffucJGRBfHACDGMa4h2gc5t43hJC3mJq5NqN9BfArhEcva",
          "weight": 1
        }]
      }
    ]
  }' -p latamlink@active

  # echo 'Set Active Validator Node'
  # cleos push action eosio setschedule \
  # '{
  #   "validators": [
  #     "eoscostarica"
  #   ]
  # }' -p eosio@active

  echo 'Register Boot Node'
  cleos push action eosio addboot \
  '{
    "entity": "latamlink",
    "name": "boot1"
  }' -p latamlink@active

  # Set Boot Node Info
  # cleos push action eosio setnodeinfo $WORK_DIR/utils/boot.json -p eosio@active

  echo 'Show writer account'
  cleos get account writer

  echo 'Register Writer'
  cleos push action eosio addwriter \
  '{
	"name": "writer1",
	"entity": "latamlink",
	"writer_authority": {
		"threshold": 1,
		"keys": [{
			"key": "'$pub'",
			"weight": 1
		}],
		"accounts": [],
		"waits": []
	  }
  }' -p latamlink@active 


  # Set Writer Node Info
  # cleos push action eosio setnodeinfo $WORK_DIR/utils/writer.json -p eosio@active

  echo 'Register Observer'
  cleos push action eosio addobserver \
  '{
    "entity": "latamlink",
    "observer": "observer1"
  }' -p latamlink@active

  # Set Observer Node Info
  # cleos push action eosio setnodeinfo $WORK_DIR/utils/writer.json -p eosio@active

  echo 'Check Nodes Table'
  cleos get table eosio eosio node


  echo 'Set schedule'
  cleos push action eosio setschedule '[["validator1"],["validator2"],["validator3"]]' -p eosio
  cleos get schedule

# Create Account for Smart Contract
echo 'Creating end user account'

cleos push action eosio newaccount \
  '{
      "creator" : "latamlink",
      "name" : "user1",
      "active" : {
          "threshold":2,
          "keys":[ {"weight":1,"key":"EOS8mnEwNj2F8Qjwr3NUyViXgLPxW2r6bL8Yuyg7wPXraD36cpUnT"}],
          "accounts":[ {"weight":1, "permission" :{"actor":"writer", "permission":"access"}}], "waits":[]
      },
      "owner" : {
          "threshold":2,
          "keys":[ {"weight":1,"key":"EOS8mnEwNj2F8Qjwr3NUyViXgLPxW2r6bL8Yuyg7wPXraD36cpUnT"}],
          "accounts":[{"weight":1, "permission" :{"actor":"writer", "permission":"access"}}], "waits":[]
      },
  }' -p latamlink@active

}

run_bios() {
  echo 'Initializing BIOS sequence...'
  create_wallet
  create_system_accounts
  deploy_system_contracts
  set_msig_privileged_account
  set_lacchain_permissioning
}
