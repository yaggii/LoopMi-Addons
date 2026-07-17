ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base-debian:bookworm
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY rootfs /
COPY run.sh /run.sh

RUN chmod a+x /run.sh \
    && mkdir -p /app /data/logs /config/loopmi

EXPOSE 5034

CMD ["/run.sh"]
