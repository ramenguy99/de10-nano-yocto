#!/bin/bash -xe

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

mkdir -p ${SCRIPT_DIR}/backup/

ssh fpga date -s @$(date -u +"%s")
ssh fpga mount /dev/mmcblk0p2 /mnt

# Backup
scp fpga:/mnt/socfpga_cyclone5_de10_nano_soc.dtb  ${SCRIPT_DIR}/backup/$(date +"%Y%m%d-%H%M%S")_socfpga_cyclone5_de10_nano_soc.dtb

# DTB=${SCRIPT_DIR}/build/tmp/work/cyclone5-poky-linux-gnueabi/linux-socfpga-lts/6.6.37-lts+git/linux-cyclone5-standard-build/arch/arm/boot/dts/intel/socfpga/socfpga_cyclone5_de10_nano_soc.dtb
DTB=${SCRIPT_DIR}/build/tmp/work/cyclone5-poky-linux-gnueabi/linux-socfpga-lts/6.6.37-lts+git/deploy-linux-socfpga-lts/socfpga_cyclone5_de10_nano_soc.dtb

# Overwrite existing
scp ${DTB} fpga:/mnt/
ssh fpga ls -l /mnt

# Cleanup
ssh fpga umount /mnt
ssh fpga sync
