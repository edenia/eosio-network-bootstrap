FROM ubuntu:18.04 as base-stage

ENV WORK_DIR /opt/application
ENV EOSIO_PACKAGE_URL https://github.com/EOSIO/eos/releases/download/v2.0.5/eosio_2.0.5-1-ubuntu-18.04_amd64.deb

# We need the recommended extra installs that come with
# wget package so it can handle SSL calls, also
# we can't remove the lists and apt cache just yet
# so we can install the eosio package properly
# hadolint ignore=DL3008,DL3009,DL3015
RUN apt-get update && apt-get install -y wget jq

# Install EOSIO
RUN wget -O eosio.deb $EOSIO_PACKAGE_URL
# hadolint ignore=DL3008,DL3015
RUN apt-get install -y /eosio.deb
# Remove all of the unnecesary files and apt cache
RUN rm ./eosio.deb \
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
ENV CONFIG_DIR $WORK_DIR
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
ENV CONFIG_DIR $WORK_DIR
ENV BACKUPS_DIR /root/backups

RUN mkdir -p $DATA_DIR

# RUN chmod +x $WORK_DIR/start.sh

CMD ["/opt/application/start.sh"]
