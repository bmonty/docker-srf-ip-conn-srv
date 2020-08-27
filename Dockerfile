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

# SharkRF IP Connector Server
RUN mkdir -p /sharkrf \
    && mkdir -p /etc/services.d/sharkrf
COPY --from=builder /tmp/build/srf-ip-conn-srv/build/Release/srf-ip-conn-srv /sharkrf/srf-ip-conn-srv
ADD configs/config.json /sharkrf/config.json
ADD services/sharkrf.run /etc/services.d/sharkrf/run

# Web Interface
COPY --from=builder /tmp/build/srf-ip-conn-srv/dashboard /sharkrf/dashboard
RUN apt-get update && apt-get install -y nginx php-fpm \
    && mv /sharkrf/dashboard/config-example.inc.php /sharkrf/dashboard/config.inc.php \
    && mkdir -p /etc/services.d/nginx
ADD configs/nginx-default /etc/nginx/sites-available/default
ADD services/nginx.run /etc/services.d/nginx/run

# S6 Overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v2.0.0.1/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C / --exclude='./bin' && tar xzf /tmp/s6-overlay-amd64.tar.gz -C /usr ./bin

EXPOSE 65100/udp
EXPOSE 80

ENTRYPOINT ["/usr/bin/s6-svscan", "/etc/s6"]
