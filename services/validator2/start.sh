#!/usr/bin/env bash
set -e;

echo "Starting EOSIO service ..."
pid=0

nodeos=$"nodeos \
  --config-dir $CONFIG_DIR \
  --data-dir $DATA_DIR \
  -e";

p2p_peers=( \
  "bios" \
  "api-node" \
)

for peer in "${p2p_peers[@]}"; do
  nodeos="$nodeos --p2p-peer-address=$peer:9876";
done

term_handler() {
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid";
    wait "$pid";
  fi
  exit 0;
}

start_nodeos() {
    # check if we're dealing with a brand new instance
    if [ ! -d $DATA_DIR/blocks ]; then
      $nodeos --delete-all-blocks --genesis-json $WORK_DIR/genesis.json &
    elif [ -d $DATA_DIR/blocks ]; then
      $nodeos &
    fi
    sleep 10;

  if [ -z "$(pidof nodeos)" ]; then
      $nodeos --hard-replay-blockchain &
  fi
}

trap 'echo "Shutdown of EOSIO service...";kill ${!}; term_handler' 2 15;

start_nodeos

pid="$(pidof nodeos)"

while true
do
  tail -f /dev/null & wait ${!}
done
