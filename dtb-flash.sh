#!/bin/bash -xe

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

sudo mount /dev/sda2 /mnt
sudo cp ${SCRIPT_DIR}/build/tmp/work/cyclone5-poky-linux-gnueabi/linux-socfpga-lts/6.6.37-lts+git/linux-cyclone5-standard-build/arch/arm/boot/dts/intel/socfpga/socfpga_cyclone5_de10_nano_soc.dtb /mnt/
ls -l /mnt
sudo umount /mnt
sync