FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

do_deploy:append() {
	if ${@bb.utils.contains("MACHINE", "cyclone5", "true", "false", d)} ; then
		install -m 0755 ${WORKDIR}/${MACHINE}_u-boot.txt ${DEPLOYDIR}/u-boot.txt
		install -m 0644 ${WORKDIR}/u-boot.scr ${DEPLOYDIR}/u-boot.scr
	fi
}