
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
                    f.close()
}

# Target binaries are the only interest.
do_install[postfuncs] += "${@ "binary_audit_gather_abixml" if ("class-target" == d.getVar("CLASSOVERRIDE")) else "" }"
do_install[vardepsexclude] += "${@ "binary_audit_gather_abixml" if ("class-target" == d.getVar("CLASSOVERRIDE")) else "" }"

python binary_audit_abixml_compare_to_ref() {
    import glob, os
    from binaryaudit import abicheck
    
    pn = d.getVar("PN")

    dest_basedir = binary_audit_get_create_pkg_dest_basedir(d)
    cur_abixml_dir = os.path.join(dest_basedir, "abixml")
    if not os.path.isdir(cur_abixml_dir):
        bb.note("No ABI dump found in the current build for '{}' under '{}'".format(pn, cur_abixml_dir))
        return

    ref_basedir = d.getVar("BINARY_AUDIT_REFERENCE_BASEDIR")
    if len(ref_basedir) < 1:
        bb.note("BINARY_AUDIT_REFERENCE_BASEDIR not set, no reference ABI comparison to perform")
        return
    if not os.path.isdir(ref_basedir):
        bb.note("No binary audit reference ABI found under '{}'".format(ref_basedir))
        return
    bb.note("BINARY_AUDIT_REFERENCE_BASEDIR = \"{}\"".format(ref_basedir))

    cur_abidiff_dir = os.path.join(dest_basedir, "abidiff")
    if not os.path.exists(cur_abidiff_dir):
        bb.utils.mkdirhier(cur_abidiff_dir)

    for fpath in glob.iglob("{}/packages/*/{}/**".format(ref_basedir, pn), recursive = True):
        if os.path.basename(fpath) != "binaryaudit": 
            continue

        ref_abixml_dir = os.path.join(fpath, "abixml")
        if not os.path.isdir(ref_abixml_dir):
            bb.note("No ABI reference found for '{}' under '{}'".format(pn, ref_abixml_dir))
            continue

        # A correct reference history dir for this package is found, proceed
        # to see if there's something to compare
        for xml_fn in os.listdir(cur_abixml_dir):
            ref_xml_fpath = os.path.join(ref_abixml_dir, xml_fn)
            if not os.path.isfile(ref_xml_fpath):
                bb.note("File '{}' is not present in the reference ABI dump".format(xml_fn))
                continue

            cur_xml_fpath = os.path.join(cur_abixml_dir, xml_fn);
            with open(cur_xml_fpath) as f:
                xml = f.read()
                f.close()

            # Care only about DSO for now
            sn = abicheck.get_soname_from_xml(xml)
            # XXX Handle error cases, eg xml file was garbage, etc.
            if len(sn) > 0:
                # XXX Implement suppression handling
                ret, out, cmd = abicheck.compare(ref_xml_fpath, cur_xml_fpath)

                bb.note(" ".join(cmd))

                status_bits = abicheck.diff_get_bits(ret)

                cur_status_fpath = os.path.join(cur_abidiff_dir, ".".join([os.path.splitext(xml_fn)[0], "status"]))
                with open(cur_status_fpath, "w") as f:
                    k = 0
                    while k + 1 < len(status_bits):
                        f.write(status_bits[k] + "\n")
                        k = k + 1
                    f.write(status_bits[k])
                    f.close()
                cur_out_fpath = os.path.join(cur_abidiff_dir, ".".join([os.path.splitext(xml_fn)[0], "out"]))
                with open(cur_out_fpath, "w") as f:
                    f.write(out)
                    f.close()

                if abicheck.diff_is_ok(ret):
                    return

                #for n in range(8):
                #    bb.note("bit '{}': '{}'".format(n, (ret >> n) & 1))

                status_ln = " ".join(status_bits)
                if abicheck.diff_is_error(ret) or abicheck.diff_is_incompatible_change(ret):
                    # NOTE This is sufficient with USAGE_ERROR, ERROR bit will be set, too.
                    bb.error("abicheck diff bits: {}".format("".join(status_ln)))
                    bb.error("abicheck output: '{}'".format(out))

                # CHANGE doesn't imply INCOMPATIBLE_CHANGE
                if  abicheck.diff_is_change(ret) and not abicheck.diff_is_incompatible_change(ret):
                    bb.error("abicheck diff bits: {}".format("".join(status_ln)))
                    bb.warn("abicheck output: '{}'".format(out))

}

# Target binaries are the only interest.
do_install[postfuncs] += "${@ "binary_audit_abixml_compare_to_ref" if ("class-target" == d.getVar("CLASSOVERRIDE")) else "" }"
do_install[vardepsexclude] += "${@ "binary_audit_abixml_compare_to_ref" if ("class-target" == d.getVar("CLASSOVERRIDE")) else "" }"
