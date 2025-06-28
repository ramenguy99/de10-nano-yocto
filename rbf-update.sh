#!/bin/bash -xe

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

mkdir -p ${SCRIPT_DIR}/backup/

ssh fpga date -s @$(date -u +"%s")
ssh fpga mount /dev/mmcblk0p2 /mnt

# Backup
scp fpga:/mnt/soc_system.rbf  ${SCRIPT_DIR}/backup/$(date +"%Y%m%d-%H%M%S")_soc_system.rbf

# Overwrite existing
scp /work/de10-nano/devkit/cd/Demonstrations/SoC_FPGA/DE10_NANO_SoC_GHRD/custom_leds_8.rbf fpga:/mnt/soc_system.rbf
ssh fpga ls -l /mnt

# Cleanup
ssh fpga umount /mnt
ssh fpga sync
