ARG BASEIMAGE="quay.io/centos-bootc/centos-bootc:stream9"
FROM ${BASEIMAGE}

ARG OS_VERSION_MAJOR=''
ARG DRIVER_VERSION=1.15.1-15
ARG TARGET_ARCH=''
ARG KERNEL_VERSION=''
ARG REDHAT_VERSION='el9'

RUN if [ "${OS_VERSION_MAJOR}" == "" ]; then \
        . /etc/os-release \
        && export OS_VERSION_MAJOR="$(echo ${VERSION} | cut -d'.' -f 1)" ;\
       fi \
    && if [ "${TARGET_ARCH}" == "" ]; then \
       export TARGET_ARCH=$(arch) ;\
       fi \
    && if [ "${KERNEL_VERSION}" == "" ]; then \
       export KERNEL_VERSION=$(dnf info kernel | awk '/Version/ {v=$3} /Release/ {r=$3} END {print v"-"r}') ;\
       fi \
    && if [ -f /etc/redhat-release ]; then \
       dnf install -y https://mirror.stream.centos.org/9-stream/CRB/x86_64/os/Packages/ninja-build-1.10.2-6.el9.x86_64.rpm ;\
       fi \
    && if [ -f /etc/centos-release ]; then \
       dnf -y install ninja-build ;\
       fi
RUN dnf install -y make git kmod kernel-headers-${KERNEL_VERSION}.${TARGET_ARCH} \
       http://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm 
# Create the repository configuration file
RUN echo "[vault]" > /etc/yum.repos.d/vault.repo \
    && echo "name=Habana Vault" >> /etc/yum.repos.d/vault.repo \
    && echo "baseurl=https://vault.habana.ai/artifactory/rhel/9/9.2" >> /etc/yum.repos.d/vault.repo \
    && echo "enabled=1" >> /etc/yum.repos.d/vault.repo \
    && echo "gpgcheck=0" >> /etc/yum.repos.d/vault.repo
# Install habanalabs modules,firmware and libraries
RUN dnf install -y libarchive* pandoc \ 
    habanalabs-firmware-${DRIVER_VERSION}.${REDHAT_VERSION} \
    habanalabs-${DRIVER_VERSION}.${REDHAT_VERSION} \
    habanalabs-rdma-core-${DRIVER_VERSION}.${REDHAT_VERSION} \
    habanalabs-firmware-tools-${DRIVER_VERSION}.${REDHAT_VERSION} \
    habanalabs-thunk-${DRIVER_VERSION}.${REDHAT_VERSION} \
    && dnf clean all
RUN depmod -a 

