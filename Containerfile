ARG BASEIMAGE="quay.io/centos-bootc/centos-bootc:stream9"
#ARG BASEIMAGE="quay.io/centos/centos:stream9"
FROM ${BASEIMAGE}

ARG OS_VERSION_MAJOR=''
ARG DRIVER_VERSION=1.15.1-15
ARG TARGET_ARCH=''
ARG KERNEL_VERSION=''
ARG REDHAT_VERSION='el9'
# Workaround? for dnf temp dir permission issue in bootc images
RUN echo "cachedir=/tmp/dnf-cache" >> /etc/dnf/dnf.conf \
    && mkdir -p /tmp/dnf-cache && chown root:root /tmp/dnf-cache && chmod 755 /tmp/dnf-cache
RUN mkdir -p /tmp/repos-tmp-dir && chown root:root /tmp/repos-tmp-dir && chmod 1777 /tmp/repos-tmp-dir





RUN . /etc/os-release \
    && export OS_VERSION_MAJOR="${OS_VERSION_MAJOR:-$(echo ${VERSION} | cut -d'.' -f 1)}" \
    && export TARGET_ARCH="${TARGET_ARCH:-$(arch)}" \
    && if [ "${KERNEL_VERSION}" == "" ]; then \
       NEWER_KERNEL_CORE=$(dnf info kernel-core | awk -F: '/^Source/{gsub(/.src.rpm/, "", $2); print $2}' | sort -n | tail -n1) \
       && RELEASE=$(dnf info ${NEWER_KERNEL_CORE} | awk -F: '/^Release/{print $2}' | tr -d '[:blank:]') \
       && VERSION=$(dnf info ${NEWER_KERNEL_CORE} | awk -F: '/^Version/{print $2}' | tr -d '[:blank:]') \
       && export KERNEL_VERSION="${VERSION}-${RELEASE}" ;\
       fi \ 
    && yum -y update && yum -y install kernel-headers-${KERNEL_VERSION} make git kmod

RUN if [ -f /etc/centos-release ]; then \
       TMPDIR=/tmp/repos-tmp-dir yum -y update \
       && TMPDIR=/tmp/repos-tmp-dir yum -y install epel-release \
       && crb enable ;\
    fi
#RUN TMPDIR=/tmp/repos-tmp-dir yum -y install ninja-build pandoc


# Create the repository configuration file
RUN echo "[vault]" > /etc/yum.repos.d/vault.repo \
    && echo "name=Habana Vault" >> /etc/yum.repos.d/vault.repo \
    && echo "baseurl=https://vault.habana.ai/artifactory/rhel/9/9.2" >> /etc/yum.repos.d/vault.repo \
    && echo "enabled=1" >> /etc/yum.repos.d/vault.repo \
    && echo "gpgcheck=0" >> /etc/yum.repos.d/vault.repo
# Install habanalabs modules,firmware and libraries
RUN mkdir -p /temp/extra-repo && chown root:root /temp/extra-repo && chmod 1777 /temp/extra-repo    
RUN restorecon -R /tmp
RUN TMPDIR=/temp/extra-repo yum -y update && TMPDIR=/temp/extra-repo yum -y install habanalabs-firmware-${DRIVER_VERSION}.${REDHAT_VERSION} \
    habanalabs-${DRIVER_VERSION}.${REDHAT_VERSION} \
    habanalabs-rdma-core-${DRIVER_VERSION}.${REDHAT_VERSION} \
    habanalabs-firmware-tools-${DRIVER_VERSION}.${REDHAT_VERSION} \
    habanalabs-thunk-${DRIVER_VERSION}.${REDHAT_VERSION}
    
#RUN depmod -a ${KERNEL_VERSION} 

# Include growfs service
#COPY build/usr /usr

#ARG INSTRUCTLAB_IMAGE
#ARG VLLM_IMAGE

# Prepull the instructlab image
#RUN IID=$(podman --root /usr/lib/containers/storage pull oci:/run/.input/vllm) && \
#    podman --root /usr/lib/containers/storage image tag ${IID} ${VLLM_IMAGE}
#RUN IID=$(podman --root /usr/lib/containers/storage pull oci:/run/.input/instructlab-intel) && \
#    podman --root /usr/lib/containers/storage image tag ${IID} ${INSTRUCTLAB_IMAGE}
