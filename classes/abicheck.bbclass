
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

python binary_audit_abixml_compare_to_ref() {
    import glob, os
    from binaryaudit import abicheck
    
    pn = d.getVar("PN")

    cur_abixml_dir = os.path.join(os.path.join(d.getVar('BUILDHISTORY_DIR_PACKAGE'), "binaryaudit"), "abixml")
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

            # Care only about DSO for now
            sn = abicheck.get_soname_from_xml(xml)
            if len(sn) > 0:
                # XXX Implement suppression handling
                ret, out, cmd = abicheck.compare(ref_xml_fpath, cur_xml_fpath)
                # XXX Not complete yet. It's to be written out into files and
                # the exit status is to be evaluated.
                bb.note(" ".join(cmd))
                bb.note(" exit status '{}'".format(ret))
                bb.note("output: '{}'".format(out))
}

# Target binaries are the only interest.
do_install[postfuncs] += "${@ "binary_audit_abixml_compare_to_ref" if ("class-target" == d.getVar("CLASSOVERRIDE")) else "" }"
do_install[vardepsexclude] += "${@ "binary_audit_abixml_compare_to_ref" if ("class-target" == d.getVar("CLASSOVERRIDE")) else "" }"
