# meta-binaryaudit

Yocto layer for ELF binary compliance validation. Currently supported is ABI compliance checking based on
[libabigail](https://sourceware.org/git/?p=libabigail.git).

# Dependencies

* URI: http://git.yoctoproject.org/clean/cgit.cgi/poky
* Branch: dunfell|gatesgarth|hardknott|honister

# Integration

The ABI check can be activated by appending the `abicheck` bbclass the inherit list. The class will attach several function calls to handle
creationg and further usage of the ABI related data. In `local.conf`, add the following:

`INHERIT += "abicheck"`

The serialized ABI representation will be integrated into the build history. Saving the build history will allow to compare the current build
with a baseline ABI data from a previous build. This requires the variable below to be set to a buildhistory directory to be taken as a baseline:

BINARY_AUDIT_REFERENCE_BASEDIR = "/path/to/buildhistory.baseline"

