#!/usr/bin/env bash
echo "Starting BIOS Node...";
set -e;
ulimit -n 65535
ulimit -s 64000

source $(dirname $0)/bios.sh

mkdir -p $CONFIG_DIR
cp /opt/scripts/config.ini $CONFIG_DIR
cp /opt/schedule/schedule.json $CONFIG_DIR

pid=0;

[[ -f $DATA_DIR/bios_ok ]] && bios_should_run=false || bios_should_run=true;

$bios_should_run && echo "Bios script is set to run";

nodeos=$"nodeos \
  --config-dir $CONFIG_DIR \
  --data-dir $DATA_DIR \
  --blocks-dir $DATA_DIR/blocks \
  --signature-provider $EOS_PUB_KEY=KEY:$EOS_PRIV_KEY" ;

term_handler() {
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid";
    wait "$pid";
  fi
  exit 0;
}

start_nodeos() {
  echo 'Starting Bios Node on an existing network...'
  $nodeos &
  sleep 10;
  if [ -z "$(pidof nodeos)" ]; then
    $nodeos --hard-replay-blockchain &
  fi
}

start_bios_nodeos() {
  echo 'Starting new chain from genesis JSON...'
  $nodeos \
    --delete-all-blocks \
    --genesis-json /opt/genesis/genesis.json \
    &
}

set_prods() {
  echo 'Setting Block Producer Schedule...'
  until nc -zvw3 validator1 9876; do
    echo "Waiting for validator1 to be up";
    sleep 5;
  done
  until nc -zvw3 validator2 9876; do
    echo "Waiting for validator2 to be up";
    sleep 5;
  done
  until nc -zvw3 validator3 9876; do
    echo "Waiting for validator3 to be up";
    sleep 5;
  done
  sleep 30;
  cleos push action eosio setprods $CONFIG_DIR/schedule.json -p eosio@active
}

trap 'echo "Shutting down nodeos service...";kill ${!}; term_handler' 2 15;

# Start either bios script or regular nodeos
$bios_should_run && start_bios_nodeos || start_nodeos

pid="$(pidof nodeos)"

# Start bios steps
if $bios_should_run; then
  sleep 5;
  run_bios
  # sleep 30
  set_prods
  # sleep 20
  # Mark this as bios has already been run
  $bios_should_run && touch $DATA_DIR/bios_ok;
fi

while true
do
  tail -f /dev/null & wait ${!}
done
