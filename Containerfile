ARG BASEIMAGE="quay.io/centos-bootc/centos-bootc:stream9"
FROM ${BASEIMAGE}

ARG OS_VERSION_MAJOR=''
ARG DRIVER_VERSION=1.15.1-15
ARG TARGET_ARCH=''
ARG KERNEL_VERSION=''
ARG REDHAT_VERSION='el9'

RUN . /etc/os-release \
    && export OS_VERSION_MAJOR="${OS_VERSION_MAJOR:-$(echo ${VERSION} | cut -d'.' -f 1)}" \
    && export TARGET_ARCH="${TARGET_ARCH:-$(arch)}" \
    && export KERNEL_VERSION="${KERNEL_VERSION:-$(dnf info kernel | awk '/Version/ {v=$3} /Release/ {r=$3} END {print v"-"r}')}" \
    && dnf -y update && dnf -y install kernel-headers-${KERNEL_VERSION} make git kmod
 
# Create the repository configuration file
RUN echo "[vault]" > /etc/yum.repos.d/vault.repo \
    && echo "name=Habana Vault" >> /etc/yum.repos.d/vault.repo \
    && echo "baseurl=https://vault.habana.ai/artifactory/rhel/9/9.2" >> /etc/yum.repos.d/vault.repo \
    && echo "enabled=1" >> /etc/yum.repos.d/vault.repo \
    && echo "gpgcheck=0" >> /etc/yum.repos.d/vault.repo
# Install habanalabs modules,firmware and libraries
RUN if [ -f /etc/centos-release ]; then \
       dnf makecache && dnf -y update \
       && dnf -y install epel-release \
       && crb enable \
       && dnf -y install ninja-build pandoc;\
    fi \
    && dnf makecache && dnf -y update \
    && dnf install -y dkms ninja-build pandoc \
    && dnf install -y habanalabs-firmware-${DRIVER_VERSION}.${REDHAT_VERSION} \
    habanalabs-${DRIVER_VERSION}.${REDHAT_VERSION} \
    habanalabs-rdma-core-${DRIVER_VERSION}.${REDHAT_VERSION} \
    habanalabs-firmware-tools-${DRIVER_VERSION}.${REDHAT_VERSION} \
    habanalabs-thunk-${DRIVER_VERSION}.${REDHAT_VERSION} \
    && dnf clean all
RUN depmod -a ${KERNEL_VERSION} 

# Include growfs service
#COPY build/usr /usr

ARG INSTRUCTLAB_IMAGE
ARG VLLM_IMAGE

# Prepull the instructlab image
RUN IID=$(podman --root /usr/lib/containers/storage pull oci:/run/.input/vllm) && \
    podman --root /usr/lib/containers/storage image tag ${IID} ${VLLM_IMAGE}
RUN IID=$(podman --root /usr/lib/containers/storage pull oci:/run/.input/instructlab-intel) && \
    podman --root /usr/lib/containers/storage image tag ${IID} ${INSTRUCTLAB_IMAGE}
