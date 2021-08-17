# meta-binaryaudit

Yocto layer for ELF binary compliance validation.

# Dependencies

* URI: http://git.yoctoproject.org/clean/cgit.cgi/poky
* Branch: dunfell|gatesgarth|hardknott|honister

# ABI compliance

The ABI compliance mechanism relies on [libabigail](https://sourceware.org/git/?p=libabigail.git). The included libabigail recipe 

## ABI serialization

The ABI check can be activated by appending the `abicheck` bbclass to the bbclass inherit list. The class will attach several function calls to the recipe `install` tasks, in order to handle creation and further usage of the ABI related data. In `local.conf`, the following is to be added:

`INHERIT += "abicheck"`

The tool used for the ABI info serialization is [abidw](https://sourceware.org/libabigail/manual/abidw.html).

## ABI compatibility

The serialized ABI representation will be integrated into the build history. Saving the build history will allow to compare the current build
with a baseline ABI data from a previous build. This requires the variable below to be set to a buildhistory directory to be taken as a baseline:

`BINARY_AUDIT_REFERENCE_BASEDIR = "/path/to/buildhistory.baseline"`

The tools used to perform the compatibility verification is [abicompat](https://sourceware.org/libabigail/manual/abicompat.html).

## ABI error suppressions

An ABI [suppression specification file](https://sourceware.org/libabigail/manual/libabigail-concepts.html#suppr-spec-label) can be used to instruct the tooling to ignore certain types of errors.

In order to add a global suppression file, modify the variable `GLOBAL_SUPPRESSION_FILE` in `local.conf` to be the suppression's filepath:

`GLOBAL_SUPRESSION_FILE = "/path/to/suppression.file"`

To add recipe-specific suppressions, add the filepath to the suppression to the recipe's `SRC_URI` list. The suppression file must also have a name which follows the regex `abi*.suppr`. Here is an example for adding a suppression called `abi_openssl.suppr` to the `openssl` recipe:

Suppression file is located in `/path.to.poky/poky/meta/recipes-connectivity/openssl/openssl/abi_openssl.suppr`

The `SCR_URI` variable in `/path.to.poky/poky/meta/recipes-connectivity/openssl/openssl_1.1.1k.bb` looks like this:

```
SRC_URI = "http://www.openssl.org/source/openssl-${PV}.tar.gz \
           file://run-ptest \
           file://0001-skip-test_symbol_presence.patch \
           file://0001-buildinfo-strip-sysroot-and-debug-prefix-map-from-co.patch \
           file://afalg.patch \
           file://reproducible.patch \
           file://abi_openssl.suppr \
           "
```
By adding a suppression file in this manner, it will show up in the recipe's `WORKDIR` and added to the `abidiff --suppression` call.
