# Package: XLOADER 1.46-psp03.00.01.46
XLOADER_VERS = 1.46
XLOADER_EXT  = tar.bz2
XLOADER_PDIR = utils/x-loader
XLOADER_SITE = file://$(SOURCES_DIR)/$(XLOADER_PDIR)

TODAY=$(shell LANG=c date +%Y%m%d)

XLOADER_RUNTIME_INSTALL = y
XLOADER_DEPS = TOOLCHAIN

XLOADER_POSTHOSTINST = \
    $(Q)(mkdir -p $(BOOTSYS_DIR)/boot && \
    $(CP) $(XLOADER_BDIR)/x-loader.bin $(BOOTSYS_DIR)/boot/;) \
    $(call autoclean,x-loader-dirclean)

XLOADER_PLATFORM_HEADER=$(subst _config,.h,$(XLOADER_DEFCONFIG))

$(eval $(call create-common-defs,x-loader,XLOADER,-))

XLOADER_BDIR=$(XLOADER_DIR)/build-$(BUILDCONF)

$(XLOADER_DIR)/.configured: $(XLOADER_STEPS_DIR)/.patched
	$(call print-info,[CONFG] XLOADER $(XLOADER_VERS))
	$(Q)$(SED) -i -e \
	    '/CONFIG_IDENT_STRING/s/OWEN-.*-.*/OWEN-$(TODAY)-$(BUILD_VERSION)"/' \
	    $(XLOADER_SDIR)/include/configs/$(XLOADER_PLATFORM_HEADER)
	$(Q)rm -rf $(XLOADER_BDIR) && mkdir -p $(XLOADER_BDIR) && \
	    cd $(XLOADER_BDIR) && lndir $(XLOADER_SDIR) > /dev/null
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(XLOADER_BDIR) CROSS_COMPILE=$(TARGET)- \
	    $(XLOADER_DEFCONFIG) \
	    $(call do-log,$(XLOADER_BDIR)/configure.out)
	$(Q)touch $@

$(XLOADER_DIR)/.built: $(XLOADER_DIR)/.configured
	$(call print-info,[BUILD] XLOADER $(XLOADER_VERS))
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(XLOADER_BDIR) \
	    CROSS_COMPILE=$(TARGET)- ARCH=arm  \
	    $(call do-log,$(XLOADER_BDIR)/make.out)
	$(Q)touch $@

$(XLOADER_DIR)/.hostinst: $(XLOADER_DIR)/.built
	$(Q)cd $(XLOADER_BDIR) && ./signGP
	$(Q)touch $@

$(XLOADER_DIR)/.posthostinst: $(XLOADER_DIR)/.hostinst
	$(Q)touch $@

$(XLOADER_DIR)/.rtinstall: $(XLOADER_DIR)/.posthostinst
	$(Q)(mkdir -p $(BOOTSYS_DIR)/boot $(BOOTSYS_DIR)/logs && \
	    $(CP) $(XLOADER_BDIR)/x-load.bin.ift $(BOOTSYS_DIR)/boot/MLO;)
	$(Q)touch $@
