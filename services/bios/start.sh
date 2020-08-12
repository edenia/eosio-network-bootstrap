#!/usr/bin/env bash
echo "Starting BIOS Node...";
set -e;
ulimit -n 65535
ulimit -s 64000

source $(dirname $0)/utils/bios.sh

mkdir -p $CONFIG_DIR
cp $WORK_DIR/config.ini $CONFIG_DIR/config.ini

pid=0;

[[ -f /root/bios_ok ]] && bios_should_run=false || bios_should_run=true;

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
  $nodeos --delete-all-blocks --genesis-json $WORK_DIR/genesis.json &
}

set_prods() {
  echo 'Setting Block Producer Schedule...'
  cleos push action eosio setprods $WORK_DIR/utils/schedule.json -p eosio@active
}

trap 'echo "Shutting down nodeos service...";kill ${!}; term_handler' 2 15;

# Start either bios script or regular nodeos
$bios_should_run && start_bios_nodeos || start_nodeos

# Mark this as bios has already been run
$bios_should_run && touch /root/bios_ok;

pid="$(pidof nodeos)"

# Start bios steps
if $bios_should_run; then
  sleep 5;
  run_bios &
  sleep 10
  set_prods &
  sleep 20
  echo 'Bios sequence completed. Shutting down nodeos...'
  term_handler &
fi

while true
do
  tail -f /dev/null & wait ${!}
done
