#!/usr/bin/env bash
echo "Starting keosd service ..."
pid=0

term_handler() {
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid";
    wait "$pid";
  fi
  exit 0;
}

start_keosd() {
  keosd \
    --wallet-dir $DATA_DIR \
    --http-server-address=0.0.0.0:8888 \
    --http-validate-host 0 \
    --verbose-http-errors \
    &
}

trap 'echo "Terminating keosd wallet service...";kill ${!}; term_handler' 2 15;

start_keosd

pid="$!"

while true
do
  tail -f /dev/null & wait ${!}
done
