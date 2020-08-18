FROM debian:buster-slim AS builder

ENV BUILDPATH /tmp/build

RUN apt-get update \
    && apt-get install -y git build-essential cmake

RUN mkdir -p $BUILDPATH \
    && cd $BUILDPATH \	
    && git clone https://github.com/sharkrf/srf-ip-conn-srv \
    && git clone https://github.com/sharkrf/srf-ip-conn \
    && git clone https://github.com/zserge/jsmn \
    && cd jsmn \
    && git checkout 732d283ee9a2e5c34c52af0e044850576888ab09

RUN cd $BUILDPATH/srf-ip-conn-srv/build \
    && SRF_IP_CONN_PATH=$BUILDPATH/srf-ip-conn JSMN_PATH=$BUILDPATH/jsmn ./build-release.sh

FROM debian:buster-slim

WORKDIR /root/
COPY --from=builder /tmp/build/srf-ip-conn-srv/build/Release/srf-ip-conn-srv .
CMD ["./srf-ip-conn-srv", "-f"]
