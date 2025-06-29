DESCRIPTION = "Custom button driver module"

LICENSE = "CLOSED"

inherit module

FILESEXTRAPATHS:prepend := "${BSPDIR}/src:"
SRC_URI = "file://custom-button"

PR = "r0"
S = "${WORKDIR}/${PN}"

# autoload module, add to /etc/modules-load.d/
KERNEL_MODULE_AUTOLOAD += "custom-button"
