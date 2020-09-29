FROM ubuntu:18.04 as base-stage

ENV WORK_DIR /opt/scripts
ENV EOSIO_PACKAGE_URL https://github.com/eosio/eos/releases/download/v2.0.7/eosio_2.0.7-1-ubuntu-18.04_amd64.deb
ENV EOSIO_CDT_OLD_URL https://github.com/eosio/eosio.cdt/releases/download/v1.6.3/eosio.cdt_1.6.3-1-ubuntu-18.04_amd64.deb
ENV EOSIO_CDT_URL https://github.com/EOSIO/eosio.cdt/releases/download/v1.7.0/eosio.cdt_1.7.0-1-ubuntu-18.04_amd64.deb

RUN apt-get update && apt-get install -y wget jq git build-essential cmake curl netcat

RUN wget -O /eosio.deb $EOSIO_PACKAGE_URL \
  && wget -O /eosio-cdt-v1.7.0.deb $EOSIO_CDT_URL \
  && wget -O /eosio-cdt-v1.6.3.deb $EOSIO_CDT_OLD_URL

RUN apt-get install -y /eosio.deb

RUN apt-get install -y /eosio-cdt-v1.6.3.deb \
  && git clone https://github.com/EOSIO/eosio.contracts.git /opt/old-eosio.contracts \
  && cd /opt/old-eosio.contracts && git checkout release/1.8.x \
  && rm -fr build \
  && mkdir build  \
  && cd build \
  && cmake .. \
  && make -j$(sysctl -n hw.ncpu)

RUN apt-get install -y /eosio-cdt-v1.7.0.deb \
  && git clone https://github.com/eoscostarica/eosio.contracts.git /opt/eosio.contracts \
  && cd /opt/eosio.contracts && git checkout release/1.9.x \
  && rm -fr build \
  && mkdir build  \
  && cd build \
  && cmake .. \
  && make -j$(sysctl -n hw.ncpu)

# Remove all of the unnecessary files and apt cache
RUN rm -Rf /eosio*.deb \
  && apt-get remove -y wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Define working directory
WORKDIR $WORK_DIR

# ------------------------------

FROM base-stage as prod-stage

ENV WORK_DIR /opt/scripts
# Define Environment params used by start.sh
ENV DATA_DIR /data/nodeos
ENV CONFIG_DIR $DATA_DIR/config

# RUN chmod +x $WORK_DIR/start.sh

CMD ["/opt/scripts/start.sh"]

# ------------------------------

FROM base-stage as local-stage

ENV WORK_DIR /opt/scripts

RUN apt-get update \
  && apt-get install -y --no-install-recommends jq curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Define Environment params used by start.sh
ENV DATA_DIR /data/nodeos
ENV CONFIG_DIR $DATA_DIR/config

RUN mkdir -p $DATA_DIR

# RUN chmod +x $WORK_DIR/start.sh

CMD ["/opt/scripts/start.sh"]
