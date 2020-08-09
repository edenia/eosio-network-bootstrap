#!/usr/bin/env bash

set -e;

source $(dirname $0)/utils/bios.sh

mkdir -p $CONFIG_DIR

cp $WORK_DIR/config.ini $CONFIG_DIR/config.ini

echo "Starting EOSIO service ...";
pid=0;

echo "Bios script will start running...";

bios_nodeos=$"nodeos \
  --genesis-json $WORK_DIR/biosboot/genesis.json \
  --signature-provider $EOS_PUB_KEY=KEY:$EOS_PRIV_KEY \
  --max-transaction-time=10000 \
  --plugin eosio::producer_plugin \
  --plugin eosio::producer_api_plugin \
  --plugin eosio::chain_plugin \
  --plugin eosio::chain_api_plugin \
  --plugin eosio::http_plugin \
  --plugin eosio::history_api_plugin \
  --plugin eosio::history_plugin \
  --data-dir $DATA_DIR \
  --blocks-dir $DATA_DIR/blocks \
  --config-dir $CONFIG_DIR \
  --producer-name eosio \
  --http-server-address 127.0.0.1:8888 \
  --p2p-listen-endpoint 127.0.0.1:9010 \
  --access-control-allow-origin=* \
  --contracts-console \
  --http-validate-host=false \
  --verbose-http-errors \
  --enable-stale-production \
  --p2p-peer-address localhost:9011 \
  --p2p-peer-address localhost:9012 \
  --p2p-peer-address localhost:9013";

term_handler() {
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid";
    wait "$pid";
  fi
  exit 0;
}

start_nodeos() {

  if [ -z "$(pidof nodeos)" ]; then

    $nodeos --hard-replay-blockchain &

  fi
}

start_bios_nodeos() {
  $bios_nodeos &
}

trap 'echo "Terminating EOSIO service...";kill ${!}; term_handler' 2 15;

pid="$(pidof nodeos)"

validator_hostname="$(hostname)"
set -e;

run_bios &

while true
do
  tail -f /dev/null & wait ${!}
done
