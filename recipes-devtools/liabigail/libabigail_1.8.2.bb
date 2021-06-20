SUMMARY = "The ABI Generic Analysis and Instrumentation Library "
HOMEPAGE = "https://sourceware.org/libabigail"
LICENSE = "LGPLv3"
SECTION = "devel"

SHA512SUM="fa8edaf39632e26430481f15e962a098459eac087074e85ca055293ba324ec5944c45880fcb36f1c54a64652605a439cbf9247dfea9bfd3ec502cc7292dd1c8d"
SRC_URI = "https://mirrors.kernel.org/sourceware/libabigail/libabigail-${PV}.tar.gz;sha512sum=${SHA512SUM}"

LIC_FILES_CHKSUM = " \
    file://COPYING;md5=2b3c1a10dd8e84f2db03cb00825bcf95 \
"

abi_compliance_gather[noexec] = "1"

DEPENDS += "elfutils libxml2"

S = "${WORKDIR}/libabigail-${PV}"

inherit autotools pkgconfig

PACKAGECONFIG ??= "rpm python3"
PACKAGECONFIG[rpm] = "--enable-rpm,--disable-rpm,rpm"
PACKAGECONFIG[deb] = "--enable-deb,--disable-deb,deb"
PACKAGECONFIG[tar] = "--enable-tar,--disable-tar,tar"
PACKAGECONFIG[zip-archive] = "--enable-zip-archive,--disable-zip-archive,zip-archive"
PACKAGECONFIG[apidoc] = "--enable-apidoc,--disable-apidoc,apidoc"
PACKAGECONFIG[manual] = "--enable-manual,--disable-manual,manual"
PACKAGECONFIG[bash-completion] = "--enable-bash-completion,--disable-bash-completion,bash-completion"
PACKAGECONFIG[fedabipkgdiff] = "--enable-fedabipkgdiff,--disable-fedabipkgdiff,fedabipkgdiff"
PACKAGECONFIG[python3] = "--enable-python3,--disable-python3,python3"

BBCLASSEXTEND = "native nativesdk"

