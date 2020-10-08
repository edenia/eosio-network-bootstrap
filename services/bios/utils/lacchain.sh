#!/usr/bin/env bash

set_lacchain_permissioning() {
  echo 'Set Writer RAM'
  cleos push action eosio setalimits '["writer", 10485760, 0, 0]' -p eosio

  echo 'Create Network Groups'
  cleos push action eosio netaddgroup '["v1", ["validator1","validator2","validator3"]]' -p eosio@active
  cleos push action eosio netaddgroup '["b1", ["boot1"]]' -p eosio@active
  cleos push action eosio netaddgroup '["b2", []]' -p eosio@active
  cleos push action eosio netaddgroup '["w1", ["writer1"]]' -p eosio@active
  cleos push action eosio netaddgroup '["o1", ["observer1"]]' -p eosio@active

  echo 'Inspect Groups Table'
  cleos get table eosio eosio netgroup
}

set_full_partner_entity() {
  echo 'Create BIOS Partner Account'

  keys=($(cleos create key --to-console))
  pub=${keys[5]}
  priv=${keys[2]}

  echo $priv >/opt/application/secrets/entity.key
  echo $pub >/opt/application/secrets/entity.pub

  cleos wallet import --private-key $priv

  echo 'Create Partner Entity'
  cleos push action eosio addentity '["latamlink", 1, '$pub']' -p eosio@active

  echo 'Get Partner Entity Account'
  cleos get account latamlink

  echo 'Set Entity Info'
  cleos push action eosio setentinfo '{"entity":"latamlink", "info": "'$(printf %q $(cat $WORK_DIR/entity-node-info/entity.json | tr -d "\r"))'"}' -p latamlink@active

  echo 'Inspect entity Table'
  cleos get table eosio eosio entity

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
  cleos push action eosio addvalidator \
    '{
    "entity": "latamlink",
    "name": "validator2",
    "validator_authority": [
      "block_signing_authority_v0",
      {
        "threshold": 1,
        "keys": [{
          "key": '"$EOS_PUB_KEY"',
          "weight": 1
        }]
      }
    ]
  }' -p latamlink@active
  cleos push action eosio addvalidator \
    '{
    "entity": "latamlink",
    "name": "validator3",
    "validator_authority": [
      "block_signing_authority_v0",
      {
        "threshold": 1,
        "keys": [{
          "key": '"$EOS_PUB_KEY"',
          "weight": 1
        }]
      }
    ]
  }' -p latamlink@active

  echo 'Set Validator Node Group'
  cleos push action eosio netsetgroup '["validator1", ["b1","b2"]]' -p eosio@active
  cleos push action eosio netsetgroup '["validator2", ["b1","b2"]]' -p eosio@active
  cleos push action eosio netsetgroup '["validator3", ["b1","b2"]]' -p eosio@active

  echo 'Set Validator Node Info'
  cleos push action eosio setnodeinfo '{"node":"validator1", "info": "'$(printf %q $(cat $WORK_DIR/entity-node-info/validator1.json | tr -d "\r"))'"}' -p latamlink@active
  cleos push action eosio setnodeinfo '{"node":"validator2", "info": "'$(printf %q $(cat $WORK_DIR/entity-node-info/validator2.json | tr -d "\r"))'"}' -p latamlink@active
  cleos push action eosio setnodeinfo '{"node":"validator3", "info": "'$(printf %q $(cat $WORK_DIR/entity-node-info/validator3.json | tr -d "\r"))'"}' -p latamlink@active

  echo 'Register Boot Node'
  cleos push action eosio addboot \
    '{
    "entity": "latamlink",
    "name": "boot1"
  }' -p latamlink@active

  echo 'Set Boot Node Group'
  cleos push action eosio netsetgroup '["boot1", ["v1","w1","o1"]]' -p eosio@active

  echo 'Set Boot Node Info'
  cleos push action eosio setnodeinfo '{"node":"boot1", "info": "'$(printf %q $(cat $WORK_DIR/entity-node-info/boot.json | tr -d "\r"))'"}' -p latamlink@active

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

  echo 'Set Writer Node Group'
  cleos push action eosio netsetgroup '["writer1", ["b1"]]' -p eosio@active

  echo 'Set Writer Node Info'
  cleos push action eosio setnodeinfo '{"node":"writer1", "info": "'$(printf %q $(cat $WORK_DIR/entity-node-info/writer.json | tr -d "\r"))'"}' -p latamlink@active

  echo 'Show writer account'
  cleos get account writer

  echo 'Register Observer'
  cleos push action eosio addobserver \
    '{
    "entity": "latamlink",
    "observer": "observer1"
  }' -p latamlink@active

  echo 'Set Observer Node Group'
  cleos push action eosio netsetgroup '["observer1", ["b1"]]' -p eosio@active

  echo 'Set Observer Node Info'
  cleos push action eosio setnodeinfo '{"node":"observer1", "info": "'$(printf %q $(cat $WORK_DIR/entity-node-info/observer.json | tr -d "\r"))'"}' -p latamlink@active

  echo 'Check Nodes Table'
  cleos get table eosio eosio node
}

set_schedule() {
  echo 'Set schedule'
  cleos push action eosio setschedule '[["validator1","validator2","validator3"]]' -p eosio
  sleep 1
  cleos get schedule
}

create_user_account() {
  echo 'Creating end user account for smart contract'
  cleos wallet import --private-key "5KawKbfwJk2VReKccdFynXwVcWZz7nVbsTQYwYYEuELsjFbKvUU"
  cleos push action eosio newaccount \
    '{
      "creator" : "latamlink",
      "name" : "eosmechanics",
      "active" : {
          "threshold":2,
          "keys":[ {"weight":1,"key":"EOS75UWSDJ7XSsneG1YTuZuZKe3CQVucwnrLnyRPB2SDUAKuuqyRL"}],
          "accounts":[ {"weight":1, "permission" :{"actor":"writer", "permission":"access"}}], "waits":[]
      },
      "owner" : {
          "threshold":2,
          "keys":[ {"weight":1,"key":"EOS75UWSDJ7XSsneG1YTuZuZKe3CQVucwnrLnyRPB2SDUAKuuqyRL"}],
          "accounts":[{"weight":1, "permission" :{"actor":"writer", "permission":"access"}}], "waits":[]
      },
  }' -p latamlink@writer

  echo 'set RAM for eosmechanics'
  cleos push action eosio setram \
    '{
    "entity":"latamlink",
    "account":"eosmechanics",
    "ram_bytes": 200000
  }' -p latamlink@writer

  echo 'get account info for eosmechanics'
  cleos get account eosmechanics

  echo 'get account info for latamlink'
  cleos get account latamlink
}

set_user_smart_contract() {
  mkdir -p /opt/application/stdout/eosmechanics
  TEMP_DIR=/opt/application/stdout/eosmechanics
  echo 'set eosmechanics smart contract code'
  cleos set contract eosmechanics -j -d -s $WORK_DIR/eosmechanics >$TEMP_DIR/tx2.json

  echo 'writer auth'
  cleos push action -j -d -s writer run '{}' -p latamlink@writer >$TEMP_DIR/tx1.json

  echo 'merge actions'
  jq -s '[.[].actions[]]' $TEMP_DIR/tx1.json $TEMP_DIR/tx2.json >$TEMP_DIR/tx3.json

  echo 'merge transactiom'
  jq '.actions = input' $TEMP_DIR/tx1.json $TEMP_DIR/tx3.json >$TEMP_DIR/tx4.json

  echo 'sign transactiom'
  cleos push transaction $TEMP_DIR/tx4.json -p latamlink@writer -p eosmechanics@active
}

invoke_user_smart_contract() {
  TEMP_DIR=/opt/application/stdout/eosmechanics
  echo 'CPU action'
  cleos push action eosmechanics cpu -j -d -s '{}' -p eosmechanics@active >$TEMP_DIR/cpu2.json

  echo 'writer auth for CPU action'
  cleos push action -j -d -s writer run '{}' -p latamlink@writer >$TEMP_DIR/cpu1.json

  echo 'merge actions'
  jq -s '[.[].actions[]]' $TEMP_DIR/cpu1.json $TEMP_DIR/cpu2.json >$TEMP_DIR/cpu3.json

  echo 'merge transactiom'
  jq '.actions = input' $TEMP_DIR/cpu1.json $TEMP_DIR/cpu3.json >$TEMP_DIR/cpu4.json

  echo 'sign transactiom'
  cleos push transaction $TEMP_DIR/cpu4.json -p latamlink@writer -p eosmechanics@active
}

run_lacchain() {
  echo 'Initializing Local LAC-Chain Testnet !'
  set_lacchain_permissioning
  set_full_partner_entity
  set_schedule
  create_user_account
  set_user_smart_contract
  invoke_user_smart_contract
  echo 'LAC Chain Setup Ready !'
}
