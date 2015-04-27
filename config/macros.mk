# Useful macros
#
autoclean = $(if $(filter $(call uc,$(AUTO_CLEAN)),TRUE),$(MAKE) $(1))

do-fakeroot = PATH=$(BINARIES_DIR)/x86/fakeroot:$(TARGET_DIR)/bin:$$PATH \
    fakeroot $1

do-fakeroot-load = PATH=$(BINARIES_DIR)/x86/fakeroot:$(TARGET_DIR)/bin:$$PATH \
    fakeroot -i $(FAKEROOT_FILE) $1

do-fakeroot-save = PATH=$(BINARIES_DIR)/x86/fakeroot:$(TARGET_DIR)/bin:$$PATH \
    fakeroot -s $(FAKEROOT_FILE) $1

do-fakeroot-inst = PATH=$(BINARIES_DIR)/x86/fakeroot:$(TARGET_DIR)/bin:$$PATH \
    fakeroot -i $(FAKEROOT_FILE) -s $(FAKEROOT_FILE) $1

ifeq "$(VERBOSE)" "TRUE"
do-log = $(shell echo '2>&1 | tee $1; ( for i in $${PIPESTATUS[@]}; do if [ "$$i" -ne "0" ]; then exit $$i; fi; done; )')
else
do-log = $(shell echo '> $1 2>&1')
endif

dlist = $(foreach d,$1,$(if $(wildcard $d),,$d))
make-dir = $(if $(strip $(call dlist $1)),,mkdir -p $(call dlist $1))

deplist_p = $(filter-out %.mk,$(shell cat $($(1)_DEPEND_TARGET)))
deplist_m = $(filter %.mk,$(shell cat $($(1)_DEPEND_TARGET)))
any-prereq = $(filter-out $(PHONY),$?) $(filter-out $(PHONY) $(wildcard $^),$^)
# Execute command if command has changed or prerequisite(s) are updated.
#
if_changed = $(if $(strip $(any-prereq)),  \
	@set -e;                           \
	echo "NEWER!")

# get current dependency list (controlled by variables)
#
patch-dep = $(if $(filter $(call uc,$(PATCH_DEPS)),TRUE),$(1))
mk-dep    = $(if $(filter $(call uc,$(MK_DEPS)),TRUE),$(1))
deplist   = $(strip				\
              $(call patch-dep,			\
                $(filter-out %.mk,$(1)))	\
              $(call mk-dep,			\
                $(filter %.mk,$(1))))

emp = $(if $(filter-out 1,$(words $(1))),$(1))
curdep = $(call emp,$(firstword $(1)) $(call deplist,$(wordlist 2,50,$(1))))

# get list of patch and .mk files
#
globdep = $(strip				\
            $(sort				\
              $(wildcard $($(1)_PATCH_DIR)/*))	\
              $(wildcard $($(1)_PATCH_DIR)/../*.mk)) 

INFLATE.bz2 = $(BZCAT)
INFLATE.tbz = $(BZCAT)
INFLATE.gz  = $(ZCAT)
INFLATE.tgz = $(ZCAT)
INFLATE.tar = cat

print-info = $(info [$(shell date +"%F %T")] -- $(1) -- )

getfile = $(if $(findstring file://,$(1)),$(CP) $(subst file:/,,$(1)) ., \
    $(WGET) $(1))

define fetch-remote
	@mkdir -p $(1) && \
	    cd $(1) && \
$(if $(filter $(call uc,$(MIRROR_ONLY)),TRUE), \
		$(WGET) $(MIRROR_SITE)/$(notdir $(2)), \
		$(call getfile,$(2)) || $(WGET) $(MIRROR_SITE)/$(notdir $(2)) )

endef

# code 1 means changes in .patch or *.mk files
# code 2 means changes in .patch list
define clean-package
	$(Q)echo "Have to rebuild the package [code $(2)] $(1)..."
	$(Q)$(SUDO) rm -rf $($(PKG)_SDIR)
endef

$(DOWNLOAD_DIR)/%:
	$(call print-info,[FETCH] $(PKG) $($(PKG)_VERS))
	$(Q)$(call fetch-remote,$($(PKG)_DL_DIR),$($(PKG)_SOURCE_URL))
	$(Q)$(foreach file,$($(PKG)_FILES),$(call fetch-remote,$($(PKG)_DL_DIR),$($(PKG)_SITE)/$(file)))

$(PKGSTEPS_DIR)/%/.dirprep: $(DOWNLOAD_DIR)/% $(PKGSTEPS_DIR)/%/.deplist \
    $(PKGSTEPS_DIR)/%/.depfile
	$(call print-info,[MKDIR] $(PKG) $($(PKG)_VERS))
#	$(Q)echo "Newer prepeq are: $(?F)"
	$(if $(filter-out 3,$(words $(?F))),$(call clean-package,$(PKG),$(words $(?F))),)
	$(Q)mkdir -p $(PKGSOURCE_DIR) $($(PKG)_STEPS_DIR)
	$(Q)touch $@

$(PKGSTEPS_DIR)/%/.depfile: $(PKGSTEPS_DIR)/%/.deplist
	$(Q)touch $@

$(PKGSTEPS_DIR)/%/.unpacked: $(PKGSTEPS_DIR)/%/.dirprep
	$(call print-info,[UNPAC] $(PKG) $($(PKG)_VERS))
	$(Q)mkdir -p $(PKGSOURCE_DIR)
	$(Q)$(INFLATE$(suffix $($(PKG)_EXT))) $($(PKG)_SOURCE_TARGET) | \
	    $(TAR) -C $(PKGSOURCE_DIR) $(UNTAR_OPTS) -
	$(Q)touch $@

$(PKGSTEPS_DIR)/%/.patched: $(PKGSTEPS_DIR)/%/.unpacked
	$(call print-info,[PATCH] $(PKG) $($(PKG)_VERS))
	$(Q)mkdir -p $($(PKG)_BDIR) && scripts/patch-kernel.sh \
	    $($(PKG)_SDIR) $($(PKG)_PATCH_DIR)/ \*.{patch,gz,bz2} \
	    $(call do-log,$($(PKG)_BDIR)/patch.out)
	$(Q)touch $@

$(PKGBUILD_DIR)/%/.configured: $(PKGSTEPS_DIR)/%/.patched
	$(call print-info,[CONFG] $(PKG) $($(PKG)_VERS))
	$(Q)mkdir -p $($(PKG)_BDIR) && cd $($(PKG)_BDIR) && \
	    $($(PKG)_CONFIG_VARS) \
	    $($(PKG)_SDIR)/$(CONFIGURE) $($(PKG)_CONFIG_OPTS) \
	    $(call do-log,$($(PKG)_BDIR)/configure.out)
	$(Q)touch $@

$(PKGBUILD_DIR)/%/.built: $(PKGBUILD_DIR)/%/.configured
	$(call print-info,[BUILD] $(PKG) $($(PKG)_VERS))
	$(Q)$($(PKG)_MAKE_VARS) \
	    $(MAKE) -C $($(PKG)_BDIR) $($(PKG)_MAKE_TARGS) \
	    $(call do-log,$($(PKG)_BDIR)/make.out)
	$(Q)touch $@

$(PKGBUILD_DIR)/%/.hostinst: $(PKGBUILD_DIR)/%/.built
	$(call print-info,[INSTL] $(PKG) $($(PKG)_VERS) to host)
	$(Q)$($(PKG)_INSTALL) $(MAKE) -C $($(PKG)_BDIR) \
	    $($(PKG)_INSTALL_TARGET) \
	    $(call do-log,$($(PKG)_BDIR)/hostinstall.out)
	$($(PKG)_EXTRA_INSTALL)
	$(Q)touch $@

$(PKGBUILD_DIR)/%/.posthostinst: $(PKGBUILD_DIR)/%/.hostinst
	$(Q)$($(PKG)_POSTHOSTINST)
	$(Q)touch $@

$(PKGBUILD_DIR)/%/.rtinstall: $(PKGBUILD_DIR)/%/.posthostinst
	$(Q)mkdir -p $(RUNTIME_DIR) $(BOOTSYS_DIR)/logs && \
	    PATH=$(TARGET_DIR)/bin:$$PATH TMP=$(PKGBUILD_DIR) \
	    installpkg -root $(RUNTIME_DIR) \
	    $(BINARIES_DIR)/arm${MACH}-runtime/$*.tgz \
	    $(call do-log,$(BOOTSYS_DIR)/logs/$*.out)
	$(Q)touch $@

$(PKGBUILD_DIR)/%/.dirclean:
	$(call print-info,[DIRCL] $(PKG) $($(PKG)_VERS))
	$(Q)$(SUDO) rm -rf $($(PKG)_SDIR) $($(PKG)_BDIR)

$(PKGBUILD_DIR)/%/.clean:
	$(call print-info,[CLEAN] $(PKG) $($(PKG)_VERS))
	$(Q)$(SUDO) rm -rf $($(PKG)_SDIR) $($(PKG)_STEPS_DIR) $($(PKG)_DIR) \
	    $(if $(findstring file://,$($(PKG)_SOURCE_URL)),$($(PKG)_DL_DIR))

$(PKGSTEPS_DIR)/%/.deplist: FORCE
#	$(call print-info,[DEPCK] $(PKG) $($(PKG)_VERS))
	$(Q)mkdir -p $($(PKG)_STEPS_DIR) ; \
	a="$(@D)/.depfile: $(strip $(sort $(wildcard $($(PKG)_PATCH_DIR)/*)) $(wildcard \
	    $($(PKG)_PATCH_DIR)/../*.mk))" ; \
	if [ -f $($(PKG)_DEPEND_TARGET) ] ; then \
	  b="`head -n 1 $($(PKG)_DEPEND_TARGET)`" ; \
	  if [ "$$a" == "$$b" ] ; then true ;\
	  else \
	    echo $$a > $($(PKG)_DEPEND_TARGET) ; \
	  fi ; \
	else \
	  echo $$a > $($(PKG)_DEPEND_TARGET) ; \
	fi

# common variable definitions
define create-common-vars

# package filename
$(2)_SRC=$(1)$(3)$$($(2)_VERS).$$($(2)_EXT)
# site to get package from
$(2)_SOURCE_URL=$$($(2)_SITE)/$$($(2)_SRC)
# path to unpacked package sources
$(2)_SDIR=$(PKGSOURCE_DIR)/$(1)-$$($(2)_VERS)
# path to put stamp files to while unpack/patch
$(2)_STEPS_DIR=$(PKGSTEPS_DIR)/$(1)-$$($(2)_VERS)
# path to put stamp files to while build
$(2)_DIR=$(PKGBUILD_DIR)/$(1)-$$($(2)_VERS)
# path to put object files to while build
$(2)_BDIR=$$($(2)_DIR)/build
# path to download package to
$(2)_DL_DIR=$(DOWNLOAD_DIR)/$(1)-$$($(2)_VERS)
# full path to downloaded package file
$(2)_SOURCE_TARGET=$$($(2)_DL_DIR)/$$($(2)_SRC)
# path to directory with patches
$(2)_PATCH_DIR=$(SOURCES_DIR)/$$($(2)_PDIR)/$$($(2)_VERS)
# install path when creating runtime package
$(2)_INSTDIR=$(PKGINST_DIR)/$(1)
# $(2)_PATCH_DEPS=$(foreach file,$($(2)_PATCHES),$(file))
$(2)_PATCH_DEPS=$(call globdep,$(2))
# all files to download
SOURCE_TARGETS+=$$($(2)_SOURCE_TARGET)
# list of packages that depend on other packages
ALL_DEPS+=$(if $($(2)_DEPS),$(2))
# prevent automatic deletion for fetched files
SCNDRY+=$($(2)_DL_DIR)

$(2)_INSTALL_TARGET=install

endef

# common generated targets
define create-common-targs

$(2)_FETCH_TARGET  = $$($(2)_SOURCE_TARGET)
ifdef $(2)_FILES
$(2)_FETCH_TARGET += $(foreach file,$($(2)_FILES),$$($(2)_DL_DIR)/$(file))
endif
$(2)_DPREP_TARGET  = $$($(2)_STEPS_DIR)/.dirprep
$(2)_DEPEND_TARGET = $$($(2)_STEPS_DIR)/.deplist
$(2)_DFILE_TARGET  = $$($(2)_STEPS_DIR)/.depfile
$(2)_UNPACK_TARGET = $$($(2)_STEPS_DIR)/.unpacked
$(2)_PATCH_TARGET  = $$($(2)_STEPS_DIR)/.patched
$(2)_CONFIG_TARGET = $$($(2)_DIR)/.configured
$(2)_BUILD_TARGET  = $$($(2)_DIR)/.built
$(2)_HOST_INSTALL  = $$($(2)_DIR)/.hostinst
$(2)_PHOST_INSTALL = $$($(2)_DIR)/.posthostinst
$(2)_CLEAN_TARGET  = $$($(2)_DIR)/.clean
$(2)_DCLEAN_TARGET = $$($(2)_DIR)/.dirclean

# proper targets with dependencies
PHONY += $(1) $(1)-fetch $(1)-unpack $(1)-patch $(1)-config $(1)-build \
    $(1)-host-install $(1)-clean $(1)-dirclean $(1)-deplist $(1)-dirprep \
    $(1)-depfile

$(1)-fetch: $$($(2)_FETCH_TARGET)
$(1)-deplist: $$($(2)_DEPEND_TARGET)
$(1)-depfile: $$($(2)_DFILE_TARGET)
$(1)-unpack: $$($(2)_UNPACK_TARGET)
$(1)-patch: $$($(2)_PATCH_TARGET)
$(1)-config: $$($(2)_CONFIG_TARGET)
$(1)-build: $$($(2)_BUILD_TARGET)
$(1)-host-install: $$($(2)_PHOST_INSTALL)
$(1)-clean: $$($(2)_CLEAN_TARGET)
$(1)-dirclean: $$($(2)_DCLEAN_TARGET)

$(1): $(1)-host-install

$$($(2)_FETCH_TARGET):  PKG=$(2)
$$($(2)_UNPACK_TARGET): PKG=$(2)
$$($(2)_PATCH_TARGET):  PKG=$(2)
$$($(2)_CONFIG_TARGET): PKG=$(2)
$$($(2)_BUILD_TARGET):  PKG=$(2)
$$($(2)_HOST_INSTALL):  PKG=$(2)
$$($(2)_PHOST_INSTALL): PKG=$(2)
$$($(2)_CLEAN_TARGET):  PKG=$(2)
$$($(2)_DCLEAN_TARGET): PKG=$(2)
$$($(2)_DEPEND_TARGET): PKG=$(2)
$$($(2)_DFILE_TARGET):  PKG=$(2)
$$($(2)_DPREP_TARGET):  PKG=$(2)
endef

# $1 - package name
# $2 - variable prefix
define create-install-targs
$(2)_RT_INSTALL = $$($(2)_DIR)/.rtinstall
$(1)_rt_install = $$($(2)_DIR)/.rtinstall
PHONY += $(1)-inst
$(1)-inst: $$($(2)_RT_INSTALL)
$$($(2)_RT_INSTALL): PKG=$(2)
endef

# $1 - package name
# $2 - variable prefix
# $3 - symbol in filename between package name and extension (- or .)
define create-common-defs
$(call create-common-vars,$(1),$(2),$(3))
$(call create-common-targs,$(1),$(2))
$(if $($(2)_RUNTIME_INSTALL),$(call create-install-targs,$(1),$(2)),)
endef

# $1 - path relative to RUNTIME_DIR
define rfs-to-ufs
	$(foreach item,$(UFS_ITEMS),rm -rf $(USERFS_DIR)/$(item) && mv $(RUNTIME_DIR)/$(item) $(USERFS_DIR)/$(item) && ln -s /mnt/ufs/$(item) $(RUNTIME_DIR)/$(item);)
endef

