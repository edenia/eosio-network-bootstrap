FROM ubuntu:18.04 as base-stage

ENV WORK_DIR /opt/application
ENV EOSIO_PACKAGE_URL https://github.com/eosio/eos/releases/download/v2.0.7/eosio_2.0.7-1-ubuntu-18.04_amd64.deb
ENV EOSIO_CDT_OLD_URL https://github.com/eosio/eosio.cdt/releases/download/v1.6.3/eosio.cdt_1.6.3-1-ubuntu-18.04_amd64.deb
ENV EOSIO_CDT_URL https://github.com/EOSIO/eosio.cdt/releases/download/v1.7.0/eosio.cdt_1.7.0-1-ubuntu-18.04_amd64.deb

# We need the recommended extra installs that come with
# wget package so it can handle SSL calls, also
# we can't remove the lists and apt cache just yet
# so we can install the eosio package properly
# hadolint ignore=DL3008,DL3009,DL3015
RUN apt-get update && apt-get install -y wget jq git build-essential cmake

RUN wget -O /eosio.deb $EOSIO_PACKAGE_URL \
  && wget -O /eosio-cdt-v1.7.0.deb $EOSIO_CDT_URL \
  && wget -O /eosio-cdt-v1.6.3.deb $EOSIO_CDT_OLD_URL

# hadolint ignore=DL3008,DL3015
RUN apt-get install -y /eosio.deb

RUN apt-get install -y /eosio-cdt-v1.7.0.deb \
  && git clone https://github.com/eoscostarica/eosio.contracts.git /opt/eosio.contracts \
  && cd /opt/eosio.contracts && git checkout eosio.private \
  && ./build.sh -e /usr/opt/eosio/2.0.7 -c /usr/opt/eosio.cdt/1.7.0 -y

# Remove all of the unnecesary files and apt cache
RUN rm -Rf /eosio*.deb \
  && apt-get remove -y wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Define working directory
WORKDIR $WORK_DIR

# ------------------------------

FROM base-stage as prod-stage

ENV WORK_DIR /opt/application
# Deifne Environment params used by start.sh
ENV DATA_DIR /root/data-dir
ENV CONFIG_DIR $DATA_DIR/config
ENV BACKUPS_DIR /root/backups

# RUN chmod +x $WORK_DIR/start.sh

CMD ["/opt/application/start.sh"]

# ------------------------------

FROM base-stage as local-stage

ENV WORK_DIR /opt/application

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends jq curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Deifne Environment params used by start.sh
ENV DATA_DIR /root/data-dir
ENV CONFIG_DIR $DATA_DIR/config
ENV BACKUPS_DIR /root/backups

RUN mkdir -p $DATA_DIR

# RUN chmod +x $WORK_DIR/start.sh

CMD ["/opt/application/start.sh"]
