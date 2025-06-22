FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "\
    file://50-usb.network \
"

do_install:append() {
    install -D -m 0644 ${WORKDIR}/50-usb.network ${D}${sysconfdir}/systemd/network/50-usb.network
}

FILES:${PN} += "\
    ${sysconfdir}/systemd/network/50-usb.network \
"
