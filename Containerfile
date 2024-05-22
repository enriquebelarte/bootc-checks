ARG BASEIMAGE="registry.redhat.io/rhel9/rhel-bootc:9.4"
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
       rm -rf /etc/rhsm-host \
       && yum --enablerepo=codeready-builder-for-rhel-9-x86_64-rpms install \
       && ninja-build \
       && uid_wrapper -y \
       && yum clean all -y \
       && ln -s /run/secrets/rhsm /etc/rhsm-host;\
       fi \
    && if [ -f /etc/centos-release ]; then \
       dnf -y config-manager --set-enabled crb \
       && dnf -y install epel-release epel-next-release ninja-build;\
       fi \
    && dnf install -y make git kmod kernel-headers-${KERNEL_VERSION}.${TARGET_ARCH} dkms
# Create the repository configuration file
RUN echo "[vault]" > /etc/yum.repos.d/vault.repo \
    && echo "name=Habana Vault" >> /etc/yum.repos.d/vault.repo \
    && echo "baseurl=https://vault.habana.ai/artifactory/rhel/9/9.2" >> /etc/yum.repos.d/vault.repo \
    && echo "enabled=1" >> /etc/yum.repos.d/vault.repo \
    && echo "gpgcheck=0" >> /etc/yum.repos.d/vault.repo
# Add specific kernel version to DKMS
RUN echo "DEFAULT_KERNEL=\"${KERNEL_VERSION}.${TARGET_ARCH}\"" >> /etc/dkms/framework.conf
# Install habanalabs modules,firmware and libraries
RUN dnf install -y libarchive* pandoc \ 
    habanalabs-firmware-${DRIVER_VERSION}.${REDHAT_VERSION} \
    habanalabs-${DRIVER_VERSION}.${REDHAT_VERSION} \
    habanalabs-rdma-core-${DRIVER_VERSION}.${REDHAT_VERSION} \
    habanalabs-firmware-tools-${DRIVER_VERSION}.${REDHAT_VERSION} \
    habanalabs-thunk-${DRIVER_VERSION}.${REDHAT_VERSION} \
    && dnf clean all
RUN depmod -a 

