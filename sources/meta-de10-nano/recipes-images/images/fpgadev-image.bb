require recipes-core/images/core-image-base.bb

export IMAGE_BASENAME = "fpgadev-image"

# Set this here because it depends on u-boot-socfpga-env and u-boot-socfpga-scr which are not part of any image (see below).
WKS_FILE:cyclone5 = "de10-nano.wks"
IMAGE_FSTYPES = "wic wic.bmap"

EXTRA_IMAGEDEPENDS:append = "\
    u-boot-socfpga-scr \
    u-boot-socfpga-env \
"

IMAGE_BOOT_FILES:append = " \
    u-boot.scr \
	"

# Image Root Filesystem Configuration
IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE:append = " ${@bb.utils.contains("DISTRO_FEATURES", "systemd", " + 4096", "" ,d)}"

# Customizations
IMAGE_FEATURES:append = " allow-empty-password empty-root-password"
IMAGE_INSTALL:append = "\
    mtd-utils \
"

CORE_IMAGE_EXTRA_INSTALL += "\
    packagegroup-base \
    packagegroup-base-usbgadget \
    packagegroup-basic \
    kernel-modules \
"

# refdes customizations
# RBO_RELEASE_VER = "2025.04"
# IMAGE_TYPE = "gsrd"
# EXTRA_IMAGEDEPENDS:append = " hw-ref-design"
# IMAGE_BOOT_FILES:apend = " ${MACHINE}_${IMAGE_TYPE}_ghrd/soc_system.rbf;soc_system.rbf"