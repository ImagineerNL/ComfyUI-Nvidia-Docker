FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

ARG BUILD_APT_PROXY
RUN set -eux; \
    if [ -n "${BUILD_APT_PROXY:-}" ]; then \
        echo "Using APT proxy: ${BUILD_APT_PROXY}"; \
        printf 'Acquire::http::Proxy "%s";\n' "$BUILD_APT_PROXY" \
        > /etc/apt/apt.conf.d/01proxy; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates wget gnupg; \
    rm -rf /var/lib/apt/lists/*

ARG BASE_DOCKER_FROM=nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

