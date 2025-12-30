FROM nvidia/cuda:12.5.1-devel-ubuntu24.04

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

ARG BUILD_ARCH=x86_64
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates wget gnupg; \
    rm -rf /var/lib/apt/lists/*; \
    \
    # Install NVIDIA CUDA repo keyring (adds /usr/share/keyrings/cuda-archive-keyring.gpg)
    wget -qO /tmp/cuda-keyring.deb \
        https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/${BUILD_ARCH}/cuda-keyring_1.1-1_all.deb; \
    dpkg -i /tmp/cuda-keyring.deb; \
    rm -f /tmp/cuda-keyring.deb; \
    \
    # Remove any duplicate CUDA repo definitions to avoid Signed-By conflicts
    rm -f /etc/apt/sources.list.d/cuda*.list /etc/apt/sources.list.d/cuda*.sources \
        /etc/apt/sources.list.d/nvidia*.list /etc/apt/sources.list.d/nvidia*.sources; \
    \
    # Add a single canonical CUDA repo entry using the keyring
    echo "deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/${BUILD_ARCH}/ /" \
        > /etc/apt/sources.list.d/cuda-ubuntu2404.list; \
    \
    apt-get update; \
    apt-get clean

# Extended from https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/12.5.1/ubuntu2404/runtime/Dockerfile
ENV NV_CUDNN_VERSION=9.3.0.75-1
ENV NV_CUDNN_PACKAGE_NAME="libcudnn9"
ENV NV_CUDA_ADD=cuda-12
ENV NV_CUDNN_PACKAGE="$NV_CUDNN_PACKAGE_NAME-$NV_CUDA_ADD=$NV_CUDNN_VERSION"

LABEL com.nvidia.cudnn.version="${NV_CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
  ${NV_CUDNN_PACKAGE} \
  && apt-mark hold ${NV_CUDNN_PACKAGE_NAME}-${NV_CUDA_ADD}

ARG BASE_DOCKER_FROM=nvidia/cuda:12.5.1-devel-ubuntu24.04

