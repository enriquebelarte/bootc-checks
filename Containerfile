ARG BASEIMAGE="registry.redhat.io/rhel9/rhel-bootc:9.4"
#ARG BASEIMAGE="quay.io/centos-bootc/centos-bootc:stream9"
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

RUN . /etc/os-release \
    && export OS_VERSION_MAJOR="${OS_VERSION_MAJOR:-$(echo ${VERSION} | cut -d'.' -f 1)}" \
    && export TARGET_ARCH="${TARGET_ARCH:-$(arch)}" \
    && dnf -y update && dnf -y install kernel-headers${KERNEL_VERSION:+-}${KERNEL_VERSION} make git kmod

COPY habana.repo /etc/yum.repos.d/vault.repo
RUN ls -lZd /tmp
RUN cat /proc/self/attr/current
RUN touch /tmp/libdnf.mytest
RUN ls -lZ /tmp/libdnf.mytest
RUN if grep -q -i "centos" /etc/os-release; then \
        echo "CentOS detected" &&  \
	dnf -y install 'dnf-command(config-manager)' && \
	dnf -y config-manager --set-enabled crb && \
	dnf -y install epel-release epel-next-release ; \
    elif grep -q -i "red hat" /etc/os-release; then \
        echo "Red Hat detected" && \
	subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms && \
	dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm ;\
    else \
        echo "Unsupported OS" && exit 1; \
    fi

RUN dnf -y install ninja-build pandoc


# Install habanalabs modules,firmware and libraries
#RUN dnf -y update \
#    && dnf -y install habanalabs-firmware-${DRIVER_VERSION}.${REDHAT_VERSION} \
#    habanalabs-${DRIVER_VERSION}.${REDHAT_VERSION} \
#    habanalabs-rdma-core-${DRIVER_VERSION}.${REDHAT_VERSION} \
#    habanalabs-firmware-tools-${DRIVER_VERSION}.${REDHAT_VERSION} \
#    habanalabs-thunk-${DRIVER_VERSION}.${REDHAT_VERSION}
    
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
