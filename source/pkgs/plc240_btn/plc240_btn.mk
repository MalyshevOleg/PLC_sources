# Package: PLC240_BTN
PLC240_BTN_VERS = 1.4
PLC240_BTN_EXT  = tar.gz
PLC240_BTN_PDIR = pkgs/plc240_btn
PLC240_BTN_SITE = file://$(SOURCES_DIR)/$(PLC240_BTN_PDIR)

PLC240_BTN_MAKE_VARS = $(Q)PATH=$(TARGET_DIR)/bin:$$PATH
PLC240_BTN_MAKE_TARGS = SDIR=$(PLC240_BTN_SDIR)/ \
    CROSS_COMPILE=$(TARGET)-

PLC240_BTN_RUNTIME_INSTALL = y
PLC240_BTN_DEPS = TOOLCHAIN

PLC240_BTN_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) plc240_btn-rt) \
    $(call autoclean,plc240_btn-dirclean)

$(eval $(call create-common-defs,plc240_btn,PLC240_BTN,-))

$(PLC240_BTN_DIR)/.configured: $(PLC240_BTN_STEPS_DIR)/.patched
	$(call print-info,[CONFG] PLC240_BTN $(PLC240_BTN_VERS))
	$(Q)mkdir -p $(PLC240_BTN_BDIR) && \
	$(CP) $(PLC240_BTN_SDIR)/Makefile $(PLC240_BTN_BDIR)
	$(Q)touch $@

$(PLC240_BTN_DIR)/.hostinst: $(PLC240_BTN_DIR)/.built
	$(Q)touch $@

plc240_btn-rt:
	$(Q){ rm -rf $(PLC240_BTN_INSTDIR) && \
	mkdir -p $(PLC240_BTN_INSTDIR)/sbin && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(PLC240_BTN_BDIR) SDIR=$(PLC240_BTN_SDIR)/ \
	    BINDIR=$(PLC240_BTN_INSTDIR)/sbin/ CROSS_COMPILE=$(TARGET)- \
	    install \
	    $(call do-log,$(PLC240_BTN_BDIR)/posthostinst.out); }
	$(Q)(cd $(PLC240_BTN_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) plc240_btn-$(PLC240_BTN_VERS).tgz \
		$(call do-log,$(PLC240_BTN_BDIR)/makepkg.out) && \
	    mv plc240_btn-$(PLC240_BTN_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(PLC240_BTN_INSTDIR)
