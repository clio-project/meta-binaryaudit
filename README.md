# meta-binaryaudit

Yocto layer for ELF binary compliance validation. Currently supported is ABI compliance checking based on
[libabigail](https://sourceware.org/git/?p=libabigail.git).

# Dependencies

* URI: http://git.yoctoproject.org/clean/cgit.cgi/poky
* Branch: dunfell|gatesgarth|hardknott|honister

# Integration

The ABI check can be activated by appending the `abicheck` bbclass the inherit list. The class will attach several function calls to handle
creationg and further usage of the ABI related data. In `local.conf`, add the following:

```bitbake
INHERIT += "abicheck"
```

With the class inherited, the serialized ABI representation will be integrated into the build history. Saving the build history will allow to compare the current build
with a baseline ABI data from a previous build.

After your first build to collect baseline data, set the variable below to be set to the buildhistory directory to be taken as a baseline:

```bitbake
BINARY_AUDIT_REFERENCE_BASEDIR = "/path/to/buildhistory.baseline"
```

The ABI comparison is done during [the Package QA mechanism](https://docs.yoctoproject.org/3.2/ref-manual/ref-qa-checks.html), allowing you to control whether if an ABI change is an error or a warning.  Then, to enable alerting for ABI changes, add the `abi-changed` QA test using _one of_ the lines here:

```bitbake
WARN_QA_append = " abi-changed"
# --- or ---
ERROR_QA_append = " abi-changed"
```

# Suppressions

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
