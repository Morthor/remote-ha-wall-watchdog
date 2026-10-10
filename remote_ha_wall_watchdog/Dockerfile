FROM ghcr.io/home-assistant/aarch64-base:3.22

ARG BUILD_ARCH=aarch64
ARG BUILD_VERSION=0.1.0

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="app" \
    io.hass.arch="${BUILD_ARCH}"

RUN apk add --no-cache android-tools

COPY run.sh watchdog.sh /
RUN chmod 0755 /run.sh /watchdog.sh

CMD ["/run.sh"]
