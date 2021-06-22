
inherit binaryaudit

BUILDHISTORY_FEATURES += "abicheck"

DEPENDS_append_class-target = " libabigail-native"

IMG_DIR="${WORKDIR}/image"

python binary_audit_gather_abixml() {
    import glob
    from binaryaudit import abicheck

    dest_basedir = binary_audit_get_create_pkg_dest_basedir(d)

    adir = os.path.join(dest_basedir, "abixml")
    if not os.path.exists(adir):
        bb.utils.mkdirhier(adir)

    for item in os.listdir(adir):
        itempath = os.path.join(adir, item)
        os.unlink(itempath)

    id = d.getVar("IMG_DIR")
    for fn in glob.iglob(id + "/**/**", recursive = True):
        if os.path.isfile(fn) and not os.path.islink(fn):
                if not abicheck.is_elf(fn):
                    continue

                # If there's no error, out is the XML representation
                ret, out, cmd = abicheck.serialize(fn)
                bb.note(" ".join(cmd))
                if not 0 == ret:
                    bb.error(out)
                    return                
                if not out:
                    bb.warn("Empty dump output for '{}'".format(fn))
                    return

                sn = abicheck.get_soname_from_xml(out)
                if len(sn) > 0:
                    # XXX This won't handle multiple soname within the same
                    #     recipe. However it's half as bad as with multiple
                    #     library versions recipe names need to be different.
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
                else:
                    out_fn =  os.path.join(adir, ".".join([os.path.basename(fn), "xml"]))

                with open(out_fn, "w") as f:
                    f.write(out)
}

# Target binaries are the only interest.
do_install[postfuncs] += "${@ "binary_audit_gather_abixml" if ("class-target" == d.getVar("CLASSOVERRIDE")) else "" }"
do_install[vardepsexclude] += "${@ "binary_audit_gather_abixml" if ("class-target" == d.getVar("CLASSOVERRIDE")) else "" }"

