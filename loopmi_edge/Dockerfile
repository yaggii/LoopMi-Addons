ARG BUILD_FROM=ghcr.io/home-assistant/base-debian:bookworm
FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH=aarch64

# ARGs aren't visible to the running container, only the build - re-declared as an ENV so the run script
# can export it as EdgeSync__EdgeSoftwareVersion for the app to report on check-in (§06.1).
ENV LOOPMI_EDGE_VERSION=${BUILD_VERSION}

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
