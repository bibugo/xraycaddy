FROM 1.15.6-alpine3.12 as builder

ARG XRAY_LATEST_URL="https://api.github.com/repos/XTLS/Xray-core/releases/latest"
ARG XRAY_ASSETS_NAME="Xray-linux-64.zip"

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
    cd ~; \
    wget -O /tmp/xray.zip $(curl --silent "${XRAY_LATEST_URL}" | jq -r '.assets[] | select(.name == "${XRAY_ASSETS_NAME}").browser_download_url'); \
    mkdir -p /root/xray; \
    unzip -q /tmp/xray.zip -d /root/xray; \
    rm -f /tmp/xray.zip; \
    chmod +x /root/xray/xray; \
    go get -u github.com/caddyserver/xcaddy/cmd/xcaddy; \
    xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive --with github.com/caddy-dns/cloudflare; \
    openssl req -x509 -nodes -days 365 \
        -subj  "/C=ZZ/O=Company/CN=example.com" \
        -newkey rsa:2048 -keyout /root/example.key \
        -out /root/example.crt; \
    apk del --purge .build-deps;

WORKDIR /root

FROM alpine:3.12

ADD https://github.com/just-containers/s6-overlay/releases/download/v2.1.0.2/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer /

COPY --from=builder /root/xray/xray /tmp/xray
COPY --from=builder /root/xray/geoip.dat /tmp/geoip.dat
COPY --from=builder /root/xray/geosite.dat /tmp/geosite.dat
COPY --from=builder /root/caddy /tmp/caddy

RUN \
    apk add --no-cache \
        tzdata \
        ca-certificates \
        libcap && \
    set -eux && \
    adduser -u 1026 -D -h /srv -s /bin/false srv && \
    addgroup srv users && \
    mv /tmp/caddy /usr/bin/caddy && \
    setcap cap_net_bind_service=+ep /usr/bin/caddy && \
    mkdir -p /usr/local/share/xray && \
    mv /tmp/geoip.dat /usr/local/share/xray/geoip.dat && \
    mv /tmp/geosite.dat /usr/local/share/xray/geosite.dat && \
    mv /tmp/xray /usr/bin/xray && \
    setcap cap_net_bind_service=+ep /usr/bin/xray

COPY rootfs/ /

COPY --from=builder /root/example.key /defaults/example.key
COPY --from=builder /root/example.crt /defaults/example.crt

ENV XDG_CONFIG_HOME /srv
ENV XDG_DATA_HOME /srv

VOLUME /srv

EXPOSE 80
EXPOSE 443

WORKDIR /srv

ENTRYPOINT [ "/init" ]
