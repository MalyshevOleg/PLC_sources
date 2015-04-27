# Package: ROMBOOT
ROMBOOT_VERS = 1.0
ROMBOOT_EXT  = tar.gz
ROMBOOT_PDIR = utils/romboot
ROMBOOT_SITE = file://$(SOURCES_DIR)/$(ROMBOOT_PDIR)

TODAY=$(shell LANG=c date +%Y%m%d)

ROMBOOT_RUNTIME_INSTALL = y
ROMBOOT_DEPS = TOOLCHAIN

ROMBOOT_POSTHOSTINST = \
    $(Q)(mkdir -p $(BOOTSYS_DIR)/boot && \
    $(CP) $(ROMBOOT_BDIR)/romboot.bin $(BOOTSYS_DIR)/boot/;) \
    $(call autoclean,romboot-dirclean)

$(eval $(call create-common-defs,romboot,ROMBOOT,-))

ROMBOOT_BDIR=$(ROMBOOT_DIR)/build-$(BUILDCONF)

$(ROMBOOT_DIR)/.configured: $(ROMBOOT_STEPS_DIR)/.patched
	$(call print-info,[CONFG] ROMBOOT $(ROMBOOT_VERS))
	$(Q)mkdir -p $(ROMBOOT_BDIR) && \
	    $(CP) $(ROMBOOT_SDIR)/Makefile $(ROMBOOT_BDIR)/Makefile
# update build revision number
	$(Q)$(SED) -i -e \
	    '/OWEN-/s,OWEN-.*-.*,OWEN-$(TODAY)-$(BUILD_VERSION)",' \
	    $(ROMBOOT_SDIR)/owen-release.h
	$(Q)touch $@

$(ROMBOOT_DIR)/.built: $(ROMBOOT_DIR)/.configured
	$(call print-info,[BUILD] ROMBOOT $(ROMBOOT_VERS))
	$(Q)$(SED) -i -e \
	    '/#define RAM_SIZE/s,SIZE_.*,SIZE_$(ROMBOOT_MSIZE),' \
	    -e "/#define PLC/s,PLC.*,$(ROMBOOT_IDENT)," \
	    $(ROMBOOT_SDIR)/sysconfig.h
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(ROMBOOT_BDIR) \
	    CROSS=$(TARGET)- SUFF= srcdir=$(ROMBOOT_SDIR) \
	    $(call do-log,$(ROMBOOT_BDIR)/make.out)
	$(Q)touch $@

$(ROMBOOT_DIR)/.hostinst: $(ROMBOOT_DIR)/.built
	$(Q)touch $@

$(ROMBOOT_DIR)/.posthostinst: $(ROMBOOT_DIR)/.hostinst
	$(Q)touch $@

$(ROMBOOT_DIR)/.rtinstall: $(ROMBOOT_DIR)/.posthostinst
	$(Q)(mkdir -p $(BOOTSYS_DIR)/boot $(BOOTSYS_DIR)/logs && \
	    $(CP) $(ROMBOOT_BDIR)/romboot.bin $(BOOTSYS_DIR)/boot/;)
	$(Q)touch $@
