ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base-debian:bookworm
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY rootfs /

RUN chmod a+x /etc/services.d/loopmi/run \
    && mkdir -p /app /data/logs /config/loopmi

EXPOSE 5034
