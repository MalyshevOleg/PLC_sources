#
# Makefile
#
# Author: h2o <Oleg Oleshko>
#
# Inspired by buildroot/crosstool scripts
#

BASEDIR=$(shell pwd)
SHELL=/bin/bash
ifeq ($(findstring --no-print-directory,$(MAKEFLAGS)),)
MAKEFLAGS += --no-print-directory
endif

BUILDMACH?=$(shell (uname -m) 2>/dev/null || echo unknown)

BUILD_VERSION=$(shell (cd $(BASEDIR); \
	svnver=$$(svn info | grep -E "^Revision:[ \t]+[0-9]+" | cut -d ' ' -f2); \
	if ! [ -z $$svnver ] && [ x"$$svnver" != x"$$(cat version)" ]; then \
		echo -n $$svnver > version; \
	fi; \
	cat version; ) 2> /dev/null)

PHONY :=

#OLD_SHELL := $(SHELL)
#SHELL = $(warning Building $@$(if $<, (from $<))$(if $?, ($? newer)))$(OLD_SHELL) -x

# Usefull macros & Interactive debugger for this Makefile
#
include mkdebug/gmd

# Get basic paths and settings
#
include config/configvars.mk

# How verbose all the programs are?
#
VERBOSE_TAR=-v
VERBOSE_PATCH=
VERBOSE_MAKE=
VERBOSE_CONF=
VERBOSE_WGET=
VERBOSE_COPY=-v
VERBOSE_UNZIP=
ifeq "$(VERBOSE)" "TRUE"
Q=
else
VERBOSE_TAR=
VERBOSE_WGET=-nv
VERBOSE_COPY=
VERBOSE_UNZIP=-q
Q=@
endif

TOOLCHAIN_DIR=$(PKGBUILD_DIR)/toolchain

# Command aliases
#
include config/commands.mk
include config/macros.mk
include config/hostmacros.mk

# Build rules for supported platforms
#
include config/platforms.mk
include config/maint.mk

# Build rules for separate packages
#
include source/utils/*/*.mk
include source/toolchain/*/*.mk
include source/toolchain.mk
include source/toolchain-bin.mk
include source/pkgs/*/*.mk

# Make options
#

clean-total:
	$(Q)rm -rf $(PKGSOURCE_DIR) $(PKGBUILD_DIR) $(BINARIES_DIR) \
	    $(TARGET_DIR)

clean-runtime:
	rm -f $(BUILD_DIR)/.busybox.installed
	rm -f $(BUILD_DIR)/.libjpeg.installed
	rm -f $(BUILD_DIR)/.libmng.installed
	rm -f $(BUILD_DIR)/.libpng.installed
	rm -f $(BUILD_DIR)/.lrzsz.installed
	rm -f $(BUILD_DIR)/.mtd.installed
	rm -f $(BUILD_DIR)/.uclibc.installed
	rm -f $(BUILD_DIR)/.zlib.installed
	$(MAKE) clean-runtime-dir

clean-runtime-dir:
	rm -rf $(RUNTIME_DIR)

#mk_files := $(subst $(BASEDIR)/,, \
#    $(wildcard config/*.mk source/*.mk source/*/*/*.mk))
#$(mk_files): ;
%.mk: ;
/%/Makefile: ;
Makefile: ;

# read all saved files with dependencies

dep_files := $(wildcard $(PKGBUILD_DIR)/*/.deplist)

ifneq ($(dep_files),)
# Instead of just including dependencies
# we have to check them with MK_DEPS and PATCH_DEPS settings
#
#include $(dep_files)
$(foreach df,$(dep_files),$(eval $(call curdep,$(shell cat $(df)))))
endif

$(foreach item,$(ALL_DEPS),$(eval $($(item)_CONFIG_TARGET): \
    $(foreach dp,$($(item)_DEPS), $($(dp)_PHOST_INSTALL))))

showdeps:
	#$(Q)echo $(ALL_DEPS)
	$(Q)echo $(foreach item,$(ALL_DEPS), \
		$($(item)_CONFIG_TARGET): $(foreach dp,$($(item)_DEPS), $($(dp)_HOST_INSTALL))\\n)

hexsize:
	$(Q)echo -n Platform $(BUILDCONF) ===
	$(Q)$(SED) -n -e '/setenv bootargs/p' $(BOOTSYS_DIR)/uconf.txt
	$(Q)echo -n "Kernel: "
	$(Q)echo "obase=16;`stat -c %s $(BOOTSYS_DIR)/install/uImage.bin`" | bc
	$(Q)echo -n "RootFS: "
	$(Q)echo "obase=16;`stat -c %s $(BOOTSYS_DIR)/plc.fs`" | bc
	$(Q)echo -n "UserFS: "
	$(Q)echo "obase=16;`stat -c %s $(BOOTSYS_DIR)/user.fs`" | bc

rel:
	$(Q)echo "Revision: $(BUILD_VERSION)"

PHONY += FORCE
FORCE:

# turm off parallel build when:
#  - installing packages
#  - making images

NOPARLIST = $(filter %-inst,$(PHONY))
NOPARLIST += fsimg cramfsimg

ifneq ($(filter $(NOPARLIST),$(MAKECMDGOALS)),)
.NOTPARALLEL:
endif

#ifneq ($(words $(MAKECMDGOALS)),1)
#ifneq ($(filter %-inst,$(MAKECMDGOALS)), )
# $(warning === not parallel for $(MAKECMDGOALS))
#.NOTPARALLEL:
#endif
#endif

.SECONDARY: $(SCNDRY)
.PHONY: $(PHONY)
