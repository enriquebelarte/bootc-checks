ARG BASEIMAGE="registry.redhat.io/rhel9/rhel-bootc:9.4"
#ARG BASEIMAGE="quay.io/centos-bootc/centos-bootc:stream9"
#ARG BASEIMAGE="quay.io/centos/centos:stream9"
FROM ${BASEIMAGE}

ARG OS_VERSION_MAJOR=''
ARG DRIVER_VERSION=1.15.1-15
ARG TARGET_ARCH=''
ARG KERNEL_VERSION=''
ARG REDHAT_VERSION='el9'
ARG HABANA_REPO="https://vault.habana.ai/artifactory/rhel/9/9.2"
# Workaround? for dnf temp dir permission issue in bootc images
RUN echo "cachedir=/var/tmp/dnf-cache" >> /etc/dnf/dnf.conf \
     && mkdir -p /var/tmp/dnf-cache && chown root:root /var/tmp/dnf-cache && chmod 755 /var/tmp/dnf-cache

RUN . /etc/os-release \
    && export OS_VERSION_MAJOR="${OS_VERSION_MAJOR:-$(echo ${VERSION} | cut -d'.' -f 1)}" \
    && export TARGET_ARCH="${TARGET_ARCH:-$(arch)}" \
    && dnf -y update && dnf -y install kernel-headers${KERNEL_VERSION:+-}${KERNEL_VERSION} \
       kernel-devel${KERNEL_VERSION:+-}${KERNEL_VERSION} elfutils-libelf-devel gcc make git kmod \
       vim-filesystem 

#COPY habana.repo /etc/yum.repos.d/
#RUN yum -y update

# EPEL and CRB packages (without libdnf)
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/9/Everything/x86_64/Packages/p/pandoc-common-2.14.0.3-17.el9.noarch.rpm \
    https://dl.fedoraproject.org/pub/epel/9/Everything/x86_64/Packages/p/pandoc-2.14.0.3-17.el9.x86_64.rpm \
    https://mirror.stream.centos.org/9-stream/CRB/x86_64/os/Packages/ninja-build-1.10.2-6.el9.x86_64.rpm \
    https://dl.fedoraproject.org/pub/epel/9/Everything/x86_64/Packages/d/dkms-3.0.13-1.el9.noarch.rpm

# Install packages without using libdnf
RUN rpm -ivh ${HABANA_REPO}/habanalabs-firmware-${DRIVER_VERSION}.${REDHAT_VERSION}.$(arch).rpm \
	    ${HABANA_REPO}/habanalabs-${DRIVER_VERSION}.${REDHAT_VERSION}.noarch.rpm \
	    ${HABANA_REPO}/habanalabs-rdma-core-${DRIVER_VERSION}.${REDHAT_VERSION}.noarch.rpm \
	    ${HABANA_REPO}/habanalabs-firmware-tools-${DRIVER_VERSION}.${REDHAT_VERSION}.$(arch).rpm \
	    ${HABANA_REPO}/habanalabs-thunk-${DRIVER_VERSION}.${REDHAT_VERSION}.$(arch).rpm

# Install habanalabs modules,firmware and libraries
#RUN dnf -y install habanalabs-firmware-${DRIVER_VERSION}.${REDHAT_VERSION} \
#    habanalabs-${DRIVER_VERSION}.${REDHAT_VERSION} \
#    habanalabs-rdma-core-${DRIVER_VERSION}.${REDHAT_VERSION} \
#    habanalabs-firmware-tools-${DRIVER_VERSION}.${REDHAT_VERSION} \
#    habanalabs-thunk-${DRIVER_VERSION}.${REDHAT_VERSION}
    
RUN depmod -a ${KERNEL_VERSION} 

# Include growfs service
COPY build/usr /usr

#ARG INSTRUCTLAB_IMAGE
#ARG VLLM_IMAGE

# Prepull the instructlab image
#RUN IID=$(podman --root /usr/lib/containers/storage pull oci:/run/.input/vllm) && \
#    podman --root /usr/lib/containers/storage image tag ${IID} ${VLLM_IMAGE}
#RUN IID=$(podman --root /usr/lib/containers/storage pull oci:/run/.input/instructlab-intel) && \
#    podman --root /usr/lib/containers/storage image tag ${IID} ${INSTRUCTLAB_IMAGE}
