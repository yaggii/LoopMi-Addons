ARG BUILD_FROM=ghcr.io/home-assistant/base-debian:bookworm
FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH=aarch64

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY rootfs /

RUN chmod a+x /etc/services.d/loopmi/run \
    && mkdir -p /app /data/logs /config/loopmi

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="app" \
    io.hass.arch="${BUILD_ARCH}" \
    org.opencontainers.image.title="LoopMi Edge Home Assistant App" \
    org.opencontainers.image.description="LoopMi Edge Native AOT runtime packaged as a Home Assistant App." \
    org.opencontainers.image.source="https://github.com/yaggii/LoopMi" \
    org.opencontainers.image.licenses="Apache License 2.0"

EXPOSE 5034
