#!/bin/bash

DKMS_CONF_PATH="/usr/src/habanalabs-${DRIVER_VERSION}/dkms.conf"

if [ -f "$DKMS_CONF_PATH" ]; then
    sed -i "s|$kernelver|$KERNELVER|g" "$DKMS_CONF_PATH"
else
    echo "dkms.conf not found at $DKMS_CONF_PATH"
    exit 1
fi
