FROM gcc:4.9

# App specific Environment variables
ENV APP=pipelinedb_kafka
ENV PROJECT_HOME=/usr/local/src/${APP}
ENV RDKAFKA_VERSION 0.9.4

RUN mkdir -p $PROJECT_HOME
WORKDIR $PROJECT_HOME
COPY . .

# postgresql-server-dev-all postgresql-common

RUN (set -x \
        && apt-get update \
        && apt-get install -y --no-install-recommends ca-certificates wget make gcc g++ python \
            protobuf-c-compiler libprotobuf-c0-dev libssl-dev zlib1g-dev \
        && mkdir -p /tmp/rdkafka \
        && wget -O - "https://github.com/edenhill/librdkafka/archive/v${RDKAFKA_VERSION}.tar.gz" \
            | tar xzf - -C /tmp/rdkafka --strip-components=1 \
        && cd /tmp/rdkafka \
        && ./configure --CFLAGS="-fPIC" --prefix=/usr --disable-ssl --disable-sasl \
        && make \
        && make install \
        && cd / \
        && rm -rf /tmp/rdkafka)


RUN rm /usr/bin/pg_config

ENV PIPELINEDB_VERSION 0.9.6
RUN mkdir -p /tmp/pipelinedb \
    && apt-get update \
    && wget -O /tmp/pipelinedb/debian.deb "https://www.pipelinedb.com/download/${PIPELINEDB_VERSION}/debian8" \
    && dpkg --force-overwrite --install /tmp/pipelinedb/debian.deb \
    && rm -r /tmp/pipelinedb 

RUN mkdir -p /tmp/avro-c \
    && cd /tmp/avro-c \
    && apt-get install -y cmake libjansson-dev  \
    && wget "http://apache.mirrors.spacedump.net/avro/stable/c/avro-c-1.8.1.tar.gz" \
    && gunzip avro-c-1.8.1.tar.gz \
    && tar -xf avro-c-1.8.1.tar \
    && cd avro-c-1.8.1 \
    && mkdir build \
    && cd build \
    && cmake .. \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    && make \
    && make test \
    && make install 

ENV LIBSERDE_VERSION=3.2.0
RUN mkdir -p /tmp/libserde \
      && apt-get update \
      && apt-get install -y --no-install-recommends ca-certificates unzip libcurl3 \
      && wget -O /tmp/libserde/libserde.zip "https://github.com/confluentinc/libserdes/archive/v${LIBSERDE_VERSION}.zip" \
      && cd /tmp/libserde \
      && unzip /tmp/libserde/libserde.zip \ 
      && cd /tmp/libserde/libserdes-${LIBSERDE_VERSION} \
      && ./configure \
      && make install

RUN mkdir -p /tmp/pipelinedb_kafka \
     && apt-get install -y git \
     && git clone https://github.com/pipelinedb/pipeline_kafka.git \
     && cd pipeline_kafka \
     && ./configure  \
     && make install

