# Package: BOOTSTRAP
BOOTSTRAP_VERS = 1.16
BOOTSTRAP_EXT  = zip
BOOTSTRAP_PDIR = utils/bootstrap
BOOTSTRAP_SITE = ftp://www.at91.com/pub/at91bootstrap

BOOTSTRAP_RUNTIME_INSTALL = y
BOOTSTRAP_DEPS = TOOLCHAIN

BOOTSTRAP_POSTHOSTINST = \
    $(Q)(mkdir -p $(BOOTSYS_DIR)/boot && \
    $(CP) $(BOOTSTRAP_BDIR)/bootstrap.bin $(BOOTSYS_DIR)/boot/;) \
    $(call autoclean,bootstrap-dirclean)

$(eval $(call create-common-vars,bootstrap,BOOTSTRAP,_))
BOOTSTRAP_SRC=AT91Bootstrap$(BOOTSTRAP_VERS).$(BOOTSTRAP_EXT)
BOOTSTRAP_SDIR=$(PKGSOURCE_DIR)/Bootstrap-v$(BOOTSTRAP_VERS)
BOOTSTRAP_DIR=$(PKGBUILD_DIR)/bootstrap-$(BOOTSTRAP_VERS)
BOOTSTRAP_DL_DIR=$(DOWNLOAD_DIR)/bootstrap-$(BOOTSTRAP_VERS)
$(eval $(call create-common-targs,bootstrap,BOOTSTRAP))
$(eval $(call create-install-targs,bootstrap,BOOTSTRAP))

BOOTSTRAP_BDIR=$(BOOTSTRAP_DIR)/build-$(BUILDCONF)
BOOTSTRAP_WDT = $(strip $(if $(findstring plc240,$(BUILDCONF)),-DDISABLE_WDT,\
$(if $(findstring spk210,$(BUILDCONF)),-DDISABLE_WDT)))

$(BOOTSTRAP_STEPS_DIR)/.unpacked: $(BOOTSTRAP_SOURCE_TARGET) \
$(BOOTSTRAP_STEPS_DIR)/.dirprep
	$(call print-info,[UNPAC] BOOTSTRAP $(BOOTSTRAP_VERS))
	$(Q)mkdir -p $(PKGSOURCE_DIR) $(BOOTSTRAP_BDIR)
	$(Q)$(UNZIP) $(BOOTSTRAP_SOURCE_TARGET) -d $(PKGSOURCE_DIR)
	$(Q)touch $@

$(BOOTSTRAP_DIR)/.configured: $(BOOTSTRAP_STEPS_DIR)/.patched
	$(call print-info,[CONFG] BOOTSTRAP $(BOOTSTRAP_VERS))
	$(Q)rm -f $(BOOTSTRAP_BDIR)/Makefile && mkdir -p $(BOOTSTRAP_BDIR) && \
	    ln -s $(BOOTSTRAP_SDIR)/board/at91sam9263ek/nandflash/Makefile \
		$(BOOTSTRAP_BDIR)/Makefile
	$(Q)touch $@

$(BOOTSTRAP_DIR)/.built: $(BOOTSTRAP_DIR)/.configured
	$(call print-info,[BUILD] BOOTSTRAP $(BOOTSTRAP_VERS))
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(BOOTSTRAP_BDIR) BOOTSTRAP_WDT=$(BOOTSTRAP_WDT) \
	    CROSS_COMPILE=$(TARGET)- BOOTSTRAP_PATH=$(BOOTSTRAP_SDIR) \
	    rebuild $(call do-log,$(BOOTSTRAP_BDIR)/make.out)
	$(Q)touch $@

$(BOOTSTRAP_DIR)/.hostinst: $(BOOTSTRAP_DIR)/.built
	$(Q)touch $@

$(BOOTSTRAP_DIR)/.posthostinst: $(BOOTSTRAP_DIR)/.hostinst
	$(Q)touch $@

$(BOOTSTRAP_DIR)/.rtinstall: $(BOOTSTRAP_DIR)/.posthostinst
	$(Q)(mkdir -p $(BOOTSYS_DIR)/boot $(BOOTSYS_DIR)/logs && \
	    $(CP) $(BOOTSTRAP_BDIR)/*.bin $(BOOTSYS_DIR)/boot/romboot.bin;)
	$(Q)touch $@
