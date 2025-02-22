#!/bin/bash
# Assumes that the current environment is a privileged container
# with the host mounted at /run/host.  We can basically write
# whatever we want, however we can't actually *reboot* the host.
set -euo pipefail

sysroot=/run/host
# Current stable image fixture
image=quay.io/coreos-assembler/fcos:testing-devel
# My hand-uploaded chunked images
chunked_image=quay.io/cgwalters/fcos-chunked:latest
imgref=ostree-unverified-registry:${image}
stateroot=testos

set -x

if test '!' -e "${sysroot}/ostree"; then
    ostree admin init-fs --modern "${sysroot}"
    ostree config --repo $sysroot/ostree/repo set sysroot.bootloader none
fi
if test '!' -d "${sysroot}/ostree/deploy/${stateroot}"; then
    ostree admin os-init "${stateroot}" --sysroot "${sysroot}"
fi
ostree-ext-cli container image deploy --sysroot "${sysroot}" \
    --stateroot "${stateroot}" --imgref "${imgref}"
ostree admin --sysroot="${sysroot}" status
ostree-ext-cli container image deploy --sysroot "${sysroot}" \
    --stateroot "${stateroot}" --imgref ostree-unverified-registry:"${chunked_image}"
ostree admin --sysroot="${sysroot}" status
ostree-ext-cli container image remove --repo "${sysroot}/ostree/repo" registry:"${image}" registry:"${chunked_image}"
ostree admin --sysroot="${sysroot}" undeploy 0
ostree --repo="${sysroot}/ostree/repo" refs > refs.txt
if test "$(wc -l < refs.txt)" -ne 0; then
    echo "found refs"
    cat refs.txt
    exit 1
fi

echo ok privileged integration
