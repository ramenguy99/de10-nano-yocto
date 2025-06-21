#!/bin/bash -xe

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

sudo bmaptool copy ${SCRIPT_DIR}/build/tmp/deploy/images/cyclone5/fpgadev-image-cyclone5.rootfs.wic /dev/sda
# sudo dd bs=1 count=8192 if=${SCRIPT_DIR}/build/tmp/deploy/images/cyclone5/uboot.env skip=0 of=/dev/sda seek=17408 conv=sync

sudo mount /dev/sda2 /mnt
ls -l /mnt
sudo cp /work/de10-nano/devkit/cd/Demonstrations/SoC_FPGA/DE10_NANO_SoC_GHRD/soc_system_sus.rbf /mnt/soc_system.rbf
cat /mnt/extlinux/extlinux.conf
cat /mnt/u-boot.scr
sudo umount /mnt
sync