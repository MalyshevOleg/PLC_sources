# Package: UCLIBC
UCLIBC_VERS = 0.9.30.2
UCLIBC_EXT  = tar.bz2
UCLIBC_SITE = http://www.uclibc.org/downloads
UCLIBC_PDIR = toolchain/uclibc

UCLIBC_FILES = uClibc-locale-030818.tgz
#UCLIBC_DEPS = PKGTOOLS

UCLIBC_POSTHOSTINST = $(call do-fakeroot,$(MAKE) uclibc-rt) \
    $(call autoclean,uclibc-dirclean)

$(eval $(call create-common-vars,uclibc,UCLIBC,-))
UCLIBC_SRC  = uClibc-$(UCLIBC_VERS).$(UCLIBC_EXT)
UCLIBC_SDIR = $(PKGSOURCE_DIR)/uClibc-$(UCLIBC_VERS)
UCLIBC_DIR  = $(PKGBUILD_DIR)/uClibc-$(UCLIBC_VERS)
UCLIBC_DL_DIR = $(DOWNLOAD_DIR)/uClibc-$(UCLIBC_VERS)
$(eval $(call create-common-targs,uclibc,UCLIBC))
$(eval $(call create-install-targs,uclibc,UCLIBC))

$(UCLIBC_STEPS_DIR)/.addunpack: $(UCLIBC_STEPS_DIR)/.unpacked
	$(call print-info,[UNPAC] UCLIBC $(UCLIBC_VERS) addons)
	$(Q)ln -sf $(UCLIBC_DL_DIR)/$(UCLIBC_FILES) \
	    $(PKGSOURCE_DIR)/uClibc-$(UCLIBC_VERS)/extra/locale/$(UCLIBC_FILES)
	$(Q)touch $@

$(UCLIBC_STEPS_DIR)/.patched: $(UCLIBC_STEPS_DIR)/.addunpack

$(UCLIBC_DIR)/.configured: $(UCLIBC_STEPS_DIR)/.patched $(GCC_DIR)/.gcc1.hostinst
	$(call print-info,[CONFG] UCLIBC $(UCLIBC_VERS))
	$(Q)(cd $(UCLIBC_BDIR) && lndir $(UCLIBC_SDIR) > /dev/null && \
	    cat $(UCLIBC_PATCH_DIR)/uClibc-$(UCLIBC_VERS)-$(MACH).conf | \
	    $(SED) -e 's,THE_LINUX_PATH,$(TARGET_DIR)/$(TARGET),' > .config) && \
	PATH=$(TARGET_DIR)/bin:$$PATH CROSS=$(TARGET)- \
	    $(MAKE) -C $(UCLIBC_BDIR) oldconfig \
		$(call do-log,$(UCLIBC_BDIR)/configure.out)
	$(Q)touch $@

# UCLIBC stage1
#

$(UCLIBC_DIR)/.uclibc1.built: $(UCLIBC_DIR)/.configured
	$(call print-info,[BUILD] UCLIBC $(UCLIBC_VERS) stage1)
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(UCLIBC_BDIR) \
		CROSS=$(TARGET)- headers FORCE \
	    $(call do-log,$(UCLIBC_BDIR)/make_headers.out) && \
	    $(SUDO) $(CP) $(UCLIBC_BDIR)/lib/*crt[1in].o \
		$(TARGET_DIR)/$(TARGET)/lib
	$(Q)touch $@

$(UCLIBC_DIR)/.uclibc1.hostinst: $(UCLIBC_DIR)/.uclibc1.built
	$(call print-info,[INSTL] UCLIBC $(UCLIBC_VERS) stage1)
	$(Q)$(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH) \
	    CROSS=$(TARGET)- \
	    $(MAKE) -C $(UCLIBC_BDIR) \
	    RUNTIME_PREFIX=$(TARGET_DIR)/$(TARGET)/ \
	    DEVEL_PREFIX=$(TARGET_DIR)/$(TARGET)/ \
	    install_headers \
	    $(call do-log,$(UCLIBC_BDIR)/hostinst_headers.out)
	$(Q)touch $@

$(TOOLCHAIN_DIR)/.uclibc1: $(UCLIBC_DIR)/.uclibc1.hostinst
	$(Q)touch $@

# UCLIBC stage2
#

$(UCLIBC_DIR)/.built: $(UCLIBC_DIR)/.configured $(GCC_DIR)/.gcc2.hostinst
	$(call print-info,[BUILD] UCLIBC $(UCLIBC_VERS) stage2)
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) CROSS=$(TARGET)- -C $(UCLIBC_BDIR) all \
		$(call do-log,$(UCLIBC_BDIR)/make.out)
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) CROSS=$(TARGET)- -C $(UCLIBC_BDIR)/utils hostutils utils \
		$(call do-log,$(UCLIBC_BDIR)/utils/make.out)
	$(Q)touch $@

$(UCLIBC_DIR)/.hostinst: $(UCLIBC_DIR)/.built
	$(call print-info,[INSTL] UCLIBC $(UCLIBC_VERS) stage2)
	$(Q)$(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH) \
	    $(MAKE) CROSS=$(TARGET)- PREFIX=$(TARGET_DIR)/$(TARGET) \
	    RUNTIME_PREFIX=/ DEVEL_PREFIX=/ \
	    -C $(UCLIBC_BDIR) install \
		$(call do-log,$(UCLIBC_BDIR)/make.out)
	$(Q)$(SUDO) $(CP) $(UCLIBC_BDIR)/utils/ldd.host \
	    $(TARGET_DIR)/bin/$(TARGET)-ldd
	$(Q)touch $@

$(TOOLCHAIN_DIR)/.uclibc2: $(UCLIBC_DIR)/.hostinst
	$(Q)touch $@

uclibc-rt:
	$(Q){ rm -rf $(PKGINST_DIR) && mkdir -p $(PKGINST_DIR) && \
	    mkdir -p $(BINARIES_DIR)/arm$(MACH)-runtime && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) CROSS=$(TARGET)- \
	    RUNTIME_PREFIX=$(PKGINST_DIR)/ \
	    -C $(UCLIBC_BDIR) install_runtime \
		$(call do-log,$(UCLIBC_BDIR)/posthostinst.out); }
	$(Q)(cd $(PKGINST_DIR); \
	    $(CP) $(TARGET_DIR)/$(TARGET)/lib/libgcc_s.so* lib/ ; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) uClibc-$(UCLIBC_VERS).tgz \
		$(call do-log,$(UCLIBC_BDIR)/makepkg.out) && \
	    mv uClibc-$(UCLIBC_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(PKGINST_DIR)

uclibc-unpack: $(UCLIBC_STEPS_DIR)/.addunpack

PHONY += uclibc-stage1 uclibc-stage2

uclibc-stage2: $(UCLIBC_DIR)/.posthostinst
uclibc-stage1: $(UCLIBC_DIR)/.uclibc1.hostinst
