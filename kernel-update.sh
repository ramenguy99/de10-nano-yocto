#!/bin/bash -xe

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

mkdir -p ${SCRIPT_DIR}/backup/

ssh fpga date -s @$(date -u +"%s")
ssh fpga mount /dev/mmcblk0p2 /mnt

# Backup
scp fpga:/mnt/zImage  ${SCRIPT_DIR}/backup/$(date +"%Y%m%d-%H%M%S")_zImage

# Overwrite existing
scp ${SCRIPT_DIR}/build/tmp/deploy/images/cyclone5/zImage fpga:/mnt/zImage
ssh fpga ls -l /mnt

# Cleanup
ssh fpga umount /mnt
ssh fpga sync
