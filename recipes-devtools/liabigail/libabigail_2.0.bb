SUMMARY = "The ABI Generic Analysis and Instrumentation Library "
HOMEPAGE = "https://sourceware.org/libabigail"
LICENSE = "LGPLv3"
SECTION = "devel"

SHA512SUM="288f63f3495f0cd38258c50b78f30a573e43ab60494fefa22c8cba6d6776c5f94742ffea26297a232b78d25f6804f1b3f51febd59ec487733e6ef683cef2c180"
SRC_URI[md5sum] = "3972df59e3b85ad157f219c9df547fca"
SRC_URI[sha256sum] = "3704ae97a56bf076ca08fb5dea6b21db998fbbf14c4f9de12824b78db53b6fda"

SRC_URI = "https://mirrors.kernel.org/sourceware/libabigail/libabigail-${PV}.tar.gz;sha512sum=${SHA512SUM}"

LIC_FILES_CHKSUM = " \
    file://LICENSE.txt;md5=0bcd48c3bdfef0c9d9fd17726e4b7dab \
"

DEPENDS += "elfutils libxml2"

S = "${WORKDIR}/libabigail-${PV}"

inherit autotools pkgconfig

PACKAGECONFIG ??= "${@bb.utils.contains('PACKAGE_CLASSES', 'package_rpm', 'rpm', '', d)} \
                   ${@bb.utils.contains('PACKAGE_CLASSES', 'package_deb', 'deb', '', d)} \
                   tar python3"
PACKAGECONFIG[rpm] = "--enable-rpm,--disable-rpm,rpm"
PACKAGECONFIG[deb] = "--enable-deb,--disable-deb,deb"
PACKAGECONFIG[tar] = "--enable-tar,--disable-tar,tar"
PACKAGECONFIG[apidoc] = "--enable-apidoc,--disable-apidoc,apidoc"
PACKAGECONFIG[manual] = "--enable-manual,--disable-manual,manual"
PACKAGECONFIG[bash-completion] = "--enable-bash-completion,--disable-bash-completion,bash-completion"
PACKAGECONFIG[fedabipkgdiff] = "--enable-fedabipkgdiff,--disable-fedabipkgdiff,fedabipkgdiff"
PACKAGECONFIG[python3] = "--enable-python3,--disable-python3,python3"

RDEPENDS_${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'python3', 'python3', '', d)}"
RDEPENDS_${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'deb', 'dpkg', '', d)}"

BBCLASSEXTEND = "native nativesdk"

