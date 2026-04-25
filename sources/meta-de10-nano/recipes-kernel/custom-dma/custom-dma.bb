DESCRIPTION = "Custom dma driver module"

LICENSE = "CLOSED"

inherit module

FILESEXTRAPATHS:prepend := "${BSPDIR}/src:"
SRC_URI = "file://custom-dma"

PR = "r0"
S = "${WORKDIR}/${PN}"

# autoload module, add to /etc/modules-load.d/
KERNEL_MODULE_AUTOLOAD += "custom-dma"
