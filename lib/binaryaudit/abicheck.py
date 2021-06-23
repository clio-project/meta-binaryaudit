
import subprocess
from xml.etree import ElementTree

def is_elf(fn):
    with open(fn, "rb") as fd:
        exp = b"\177ELF"
        head = fd.read(4)
    return head == exp

def get_soname_from_xml(xml):
    r = ElementTree.fromstring(xml)
    try:
        return r.attrib["soname"]
    except (AttributeError, KeyError):
        return ""

def serialize(fn):
    cmd = ["abidw", "--no-corpus-path", fn]
    sout = subprocess.PIPE
    serr = subprocess.STDOUT
    shell = False
    try:
        process = subprocess.Popen(cmd, stdout=sout,
                       stderr=serr, shell=shell)
        sout, serr = process.communicate()
        out = "".join([out.decode('utf-8') for out in [sout, serr] if out])
    except OSError as err:
        raise
    # return cmd for logging purposes
    return process.returncode, out, cmd

def compare(ref, cur):
    cmd = ["abidiff", ref, cur]
    sout = subprocess.PIPE
    serr = subprocess.STDOUT
    shell = False
    try:
        process = subprocess.Popen(cmd, stdout=sout,
            stderr=serr, shell=shell)
        sout, serr = process.communicate()
        out = "".join([out.decode('utf-8') for out in [sout, serr] if out])
    except OSError as err:
        raise
    # return cmd for logging purposes
    return process.returncode, out, cmd

