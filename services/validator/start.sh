#!/usr/bin/env bash

set -x;

echo "Starting EOSIO service ..."
pid=0

nodeos=$"nodeos \
  --config-dir $CONFIG_DIR \
  --data-dir $DATA_DIR \
  -e";

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

recover_backups() {
  rm -Rf $DATA_DIR/blocks $DATA_DIR/state
  blocks_file="$(ls -t $BACKUPS_DIR/blocks*.tar.gz | head -1)";
  state_file="$(ls -t $BACKUPS_DIR/state*.tar.gz | head -1)";
  tar -xzf $blocks_file -C $DATA_DIR;
  tar -xzf $state_file -C $DATA_DIR;
}

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

trap 'echo "Terminating EOSIO service...";kill ${!}; term_handler' 2 15;

start_nodeos

pid="$(pidof nodeos)"

while true
do
  tail -f /dev/null & wait ${!}
done
