require recipes-core/images/core-image-base.bb

export IMAGE_BASENAME = "fpgadev-image"

IMAGE_FSTYPES = "wic wic.bmap"

EXTRA_IMAGEDEPENDS:append = "\
    u-boot-socfpga-scr \
    u-boot-socfpga-env \
"

IMAGE_BOOT_FILES = " \
    socfpga_cyclone5_de10_nano_soc.dtb \
	${KERNEL_IMAGETYPE} \
	extlinux.conf;extlinux/extlinux.conf \
    u-boot.scr \
	"

# Image Root Filesystem Configuration
IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE:append = " ${@bb.utils.contains("DISTRO_FEATURES", "systemd", " + 4096", "" ,d)}"

# Customizations
IMAGE_FEATURES:append = " allow-empty-password empty-root-password"
IMAGE_INSTALL:append = " mtd-utils"

# refdes customizations
# RBO_RELEASE_VER = "2025.04"
# IMAGE_TYPE = "gsrd"
# EXTRA_IMAGEDEPENDS:append = " hw-ref-design"
# IMAGE_BOOT_FILES:apend = " ${MACHINE}_${IMAGE_TYPE}_ghrd/soc_system.rbf;soc_system.rbf"