DESCRIPTION = "Custom LEDs driver module"

LICENSE = "CLOSED"

inherit module

FILESEXTRAPATHS:prepend := "${BSPDIR}/src:"
SRC_URI = "file://custom-leds"

PR = "r0"
S = "${WORKDIR}/${PN}"

# autoload module, add to /etc/modules-load.d/
KERNEL_MODULE_AUTOLOAD += "custom-leds"
