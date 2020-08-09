#!/usr/bin/env bash

set -e;

mkdir -p $CONFIG_DIR

cp $WORK_DIR/config.ini $CONFIG_DIR/config.ini

echo "Starting EOSIO service ...";
pid=0;

nodeos=$"nodeos \
  --signature-provider $EOS_PUB_KEY=KEY:$EOS_PRIV_KEY \
  --data-dir $DATA_DIR \
  --blocks-dir $DATA_DIR/blocks \
  --config-dir $CONFIG_DIR";

term_handler() {
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid";
    wait "$pid";
  fi
  exit 0;
}

start_nodeos() {
  $nodeos &

  sleep 10;

  if [ -z "$(pidof nodeos)" ]; then

    $nodeos --hard-replay-blockchain &

  fi
}

trap 'echo "Terminating EOSIO service...";kill ${!}; term_handler' 2 15;

pid="$(pidof nodeos)"

validator_hostname="$(hostname)"
set -e;

while true
do
  tail -f /dev/null & wait ${!}
done
