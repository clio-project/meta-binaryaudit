SUMMARY = "The ABI Generic Analysis and Instrumentation Library "
HOMEPAGE = "https://sourceware.org/libabigail"
LICENSE = "LGPLv3"
SECTION = "devel"

SHA512SUM="fa8edaf39632e26430481f15e962a098459eac087074e85ca055293ba324ec5944c45880fcb36f1c54a64652605a439cbf9247dfea9bfd3ec502cc7292dd1c8d"
SRC_URI[md5sum] = "bd8509b286ff39fe82107a3847ee9f39"
SRC_URI[sha256sum] = "86347c9f0a8666f263fd63f8c3fe4c4f9cb1bdb3ec4260ecbaf117d137e89787"

SRC_URI = "https://mirrors.kernel.org/sourceware/libabigail/libabigail-${PV}.tar.gz;sha512sum=${SHA512SUM}"

LIC_FILES_CHKSUM = " \
    file://COPYING;md5=2b3c1a10dd8e84f2db03cb00825bcf95 \
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
PACKAGECONFIG[zip-archive] = "--enable-zip-archive,--disable-zip-archive,zip-archive"
PACKAGECONFIG[apidoc] = "--enable-apidoc,--disable-apidoc,apidoc"
PACKAGECONFIG[manual] = "--enable-manual,--disable-manual,manual"
PACKAGECONFIG[bash-completion] = "--enable-bash-completion,--disable-bash-completion,bash-completion"
PACKAGECONFIG[fedabipkgdiff] = "--enable-fedabipkgdiff,--disable-fedabipkgdiff,fedabipkgdiff"
PACKAGECONFIG[python3] = "--enable-python3,--disable-python3,python3"

RDEPENDS_${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'python3', 'python3', '', d)}"
RDEPENDS_${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'deb', 'dpkg', '', d)}"

BBCLASSEXTEND = "native nativesdk"

