FROM golang:1.15.6-alpine3.12 as builder

RUN apk add --no-cache  --virtual .build-deps \
        build-base \
        cmake \
        boost-dev \
        openssl-dev \
        mariadb-connector-c-dev \
        git \
        ca-certificates \
        curl \
        jq \
        openssl; \
    set -eux; \
    cd /root; \
    wget -O /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip; \
    mkdir -p /root/xray; \
    unzip -q /tmp/xray.zip -d /root/xray; \
    rm -f /tmp/xray.zip; \
    chmod +x /root/xray/xray; \
    go get -u github.com/caddyserver/xcaddy/cmd/xcaddy; \
    xcaddy build --with github.com/caddy-dns/cloudflare; \
    openssl req -x509 -nodes -days 365 \
        -subj  "/C=ZZ/O=Company/CN=example.com" \
        -newkey rsa:2048 -keyout /root/example.key \
        -out /root/example.crt; \
    apk del --purge .build-deps;

WORKDIR /root

FROM alpine:3.12

ADD rootfs /
ADD https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-amd64.tar.gz /tmp/s6overlay.tar.gz

COPY --from=builder \
        /root/xray/xray \
        /root/xray/geoip.dat \
        /root/xray/geosite.dat \
        /root/caddy \
        /root/example.key \
        /root/example.crt \
        /tmp/

RUN \
    apk add --update --no-cache \
        tzdata \
        ca-certificates \
        libcap && \
    set -eux && \
    rm -rf /var/cache/apk/* && \
    tar xzf /tmp/s6overlay.tar.gz -C / && \
    rm /tmp/s6overlay.tar.gz && \
    adduser -u 1026 -D -h /srv -s /bin/false srv && \
    addgroup srv users && \
    mv /tmp/caddy /usr/bin/caddy && \
    setcap cap_net_bind_service=+ep /usr/bin/caddy && \
    mkdir -p /usr/local/share/xray && \
    mv /tmp/geoip.dat /usr/local/share/xray/geoip.dat && \
    mv /tmp/geosite.dat /usr/local/share/xray/geosite.dat && \
    mv /tmp/xray /usr/bin/xray && \
    setcap cap_net_bind_service=+ep /usr/bin/xray && \
    mv /tmp/example.key /defaults/example.key && \
    mv /tmp/example.crt /defaults/example.crt

ENV \
        XDG_CONFIG_HOME="/srv" \
        XDG_DATA_HOME="/srv"

EXPOSE 80 443

VOLUME /srv

WORKDIR /srv

ENTRYPOINT [ "/init" ]
