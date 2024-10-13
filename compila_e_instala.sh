#!/bin/bash

make clean
make
cp ~/keys-kernel-modules/signing_key.*  /lib/modules/$(uname -r)/build/certs
/usr/src/linux-headers-$(uname -r)/scripts/sign-file sha256 /lib/modules/$(uname -r)/build/certs/signing_key.priv /lib/modules/$(uname -r)/build/certs/signing_key.pem nf_conntrack_rtsp.ko
/usr/src/linux-headers-$(uname -r)/scripts/sign-file sha256 /lib/modules/$(uname -r)/build/certs/signing_key.priv /lib/modules/$(uname -r)/build/certs/signing_key.pem nf_nat_rtsp.ko
make modules_install
depmod -a
modprobe nf_nat_rtsp
exit 0
