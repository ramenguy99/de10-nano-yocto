SRCREV = "346486b5245fb21b577dbb86a0d8d609bc5d8643"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://0001-dts-arm-Add-socfpga_cyclone5_de10_nano_soc.dts.patch \
    file://usb-g-ncm.cfg \
    file://syscon-leds.cfg \
"


do_recompile_dtb() {
    cd ${B}
    oe_runmake intel/socfpga/socfpga_cyclone5_de10_nano_soc.dtb
}
addtask recompile_dtb before do_compile after do_configure