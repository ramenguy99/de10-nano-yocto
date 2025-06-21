FILESEXTRAPATHS:prepend := "${THISDIR}/env:"

SRC_URI:cyclone5 = "\
	${@bb.utils.contains("UBOOT_CONFIG", "de10-nano-soc", "file://de10-nano-soc_u-boot-env.txt", "", d)} \
"
