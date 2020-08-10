#!/usr/bin/env bash

set -e;

source $(dirname $0)/utils/bios.sh

mkdir -p $CONFIG_DIR

cp $WORK_DIR/config.ini $CONFIG_DIR/config.ini

echo "Starting EOSIO service ...";
pid=0;

[[ -f /root/bios_ok ]] && bios_should_run=false || bios_should_run=true;

$bios_should_run && echo "Bios script will start running...";

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
  --enable-stale-production ";

# nodeos=$"nodeos \
#   --config-dir $CONFIG_DIR \
#   --data-dir $DATA_DIR \
#   -e";
nodeos=$"nodeos \
  --signature-provider $EOS_PUB_KEY=KEY:$EOS_PRIV_KEY \
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
  --enable-stale-production" ;

p2p_peers=( \
  "validator" \
  "writer-api" \
)

# Add all of the p2p peers excluding itself as a peer
for peer in "${p2p_peers[@]}"; do
  # nodes=( \
  #   "$peer-0" \
  #   "$peer-1" \
  # )
  # for node in "${nodes[@]}"; do
  #   [ "$node" != "$(hostname)" ] \
  #     && nodeos="$nodeos --p2p-peer-address=$node.$peer:9876";
  # done
  nodeos="$nodeos --p2p-peer-address=$peer:9876";
done

term_handler() {
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid";
    wait "$pid";
  fi
  exit 0;
}

# recover_backups() {
#   rm -Rf $DATA_DIR/blocks $DATA_DIR/state
#   blocks_file="$(ls -t $BACKUPS_DIR/blocks*.tar.gz | head -1)";
#   state_file="$(ls -t $BACKUPS_DIR/state*.tar.gz | head -1)";
#   tar -xzf $blocks_file -C $DATA_DIR;
#   tar -xzf $state_file -C $DATA_DIR;
# }

start_nodeos() {
  # check if we're dealing with a brand new instance
  # if [ -d $BACKUPS_DIR ] && [ ! -d $DATA_DIR/blocks ]; then
  #   recover_backups
  #   $nodeos &
  # elif [ -d $DATA_DIR/blocks ]; then
  $nodeos &
  # fi

  sleep 10;

  if [ -z "$(pidof nodeos)" ]; then
    # if [ -d $BACKUPS_DIR ]; then
    #   recover_backups
    #   $nodeos &
    # else
    $nodeos --hard-replay-blockchain &
    # fi
  fi
}

start_bios_nodeos() {
  $bios_nodeos &
}

trap 'echo "Terminating EOSIO service...";kill ${!}; term_handler' 2 15;

# Start either bios script or regular nodeos
$bios_should_run && start_bios_nodeos || start_nodeos

# Mark this as bios has already been run
$bios_should_run && touch /root/bios_ok;

pid="$(pidof nodeos)"

# Start bios steps
if $bios_should_run; then
  sleep 4;
  run_bios &
fi

while true
do
  tail -f /dev/null & wait ${!}
done