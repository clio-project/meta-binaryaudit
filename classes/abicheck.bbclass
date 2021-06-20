
inherit buildhistory

BUILDHISTORY_FEATURES += "abicheck"
BUILDHISTORY_PRESERVE += "abixml"

DEPENDS_append_class-target = " libabigail-native"

IMG_DIR="${WORKDIR}/image"

python abi_compliance_gather_abixml() {
    import glob
    import subprocess
    from xml.etree import ElementTree as ET

    pn = d.getVar("PN")

    #hdir = d.getVar('BUILDHISTORY_DIR_PACKAGE')
    #if not os.path.exists(hdir):
    #    bb.utils.mkdirhier(hdir)

    #pdir = os.path.join(hdir, pn)
    #if not os.path.exists(pdir):
    #    bb.utils.mkdirhier(pdir)

    #adir = os.path.join(pdir, "abixml")
    #if not os.path.exists(adir):
    #    bb.utils.mkdirhier(adir)

    hdir = d.getVar('BUILDHISTORY_DIR_PACKAGE')
    if not os.path.exists(hdir):
        bb.utils.mkdirhier(hdir)
    adir = os.path.join(hdir, "abixml")
    if not os.path.exists(adir):
        bb.utils.mkdirhier(adir)

    for item in os.listdir(adir):
        itempath = os.path.join(adir, item)
        os.unlink(itempath)

    id = d.getVar("IMG_DIR")
    for fn in glob.iglob(id + "/**/**", recursive = True):
        if os.path.isfile(fn) and not os.path.islink(fn):
            with open(fn, "rb") as fd:
                exp = b"\177ELF"
                head = fd.read(4)
                is_elf = head == exp
                if not is_elf:
                    continue

                cmd = ["abidw", "--no-corpus-path", fn]
                bb.note(" ".join(cmd))
                sout = subprocess.PIPE
                serr = subprocess.STDOUT
                shell = False
                try:
                    process = subprocess.Popen(cmd, stdout=sout,
                                   stderr=serr, shell=shell)
                    sout, serr = process.communicate()
                    out = ''.join([out.decode('utf-8') for out in [sout, serr] if out])
                except OSError as err:
                    raise
                if not 0 == process.returncode:
                    bb.error(out)
                    return                

                if not out:
                    bb.warn("abidw output for {} is empty".format(fn))
                    return

                r = ET.fromstring(out)
                try:
                    sn = r.attrib["soname"]
                    l = sn.split(".")
                    try:
                        if 1 == len(l):
                            out_fn = os.path.join(adir, sn)
                        else:
                            nl = []
                            for p in l:
                                nl.append(p)
                                if "so" == p:
                                    break
                            nl.append("xml")
                            out_fn = os.path.join(adir, ".".join(nl))
                    except IndexError:
                        bb.warn("couldn't parse soname {}".format(sn))
                        return                
                except (AttributeError, KeyError):
                    out_fn =  os.path.join(adir, ".".join([os.path.basename(fn), "xml"]))
                with open(out_fn, "w") as f:
                    f.write(out)
}

# Target binaries are the only interest.
do_install[postfuncs] += "${@ "abi_compliance_gather_abixml" if ("class-target" == d.getVar("CLASSOVERRIDE")) else "" }"
do_install[vardepsexclude] += "${@ "abi_compliance_gather_abixml" if ("class-target" == d.getVar("CLASSOVERRIDE")) else "" }"

