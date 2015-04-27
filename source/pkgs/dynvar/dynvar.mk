# Package: DYNVAR
DYNVAR_VERS = 1.4
DYNVAR_EXT  = tar.gz
DYNVAR_PDIR = pkgs/dynvar
DYNVAR_SITE = file://$(SOURCES_DIR)/$(DYNVAR_PDIR)

DYNVAR_MAKE_VARS = $(Q)PATH=$(TARGET_DIR)/bin:$$PATH
DYNVAR_MAKE_TARGS = CROSS_COMPILE=$(TARGET)-

DYNVAR_RUNTIME_INSTALL = y
DYNVAR_DEPS = SNMP

DYNVAR_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) dynvar-rt) \
    $(call autoclean,dynvar-dirclean)

$(eval $(call create-common-defs,dynvar,DYNVAR,-))

$(DYNVAR_DIR)/.configured: $(DYNVAR_STEPS_DIR)/.patched
	$(call print-info,[CONFG] DYNVAR $(DYNVAR_VERS))
	$(Q)mkdir -p $(DYNVAR_BDIR) && cd $(DYNVAR_BDIR) && \
		lndir $(DYNVAR_SDIR) > /dev/null
	$(Q)touch $@

$(DYNVAR_DIR)/.hostinst: $(DYNVAR_DIR)/.built
	$(Q)touch $@

dynvar-rt:
	$(Q){ rm -rf $(DYNVAR_INSTDIR) && \
	mkdir -p $(DYNVAR_INSTDIR)/sbin && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(DYNVAR_BDIR) \
	    DESTDIR=$(DYNVAR_INSTDIR) CROSS_COMPILE=$(TARGET)- \
	    install \
	    $(call do-log,$(DYNVAR_BDIR)/posthostinst.out); }
	$(Q)(cd $(DYNVAR_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) dynvar-$(DYNVAR_VERS).tgz \
		$(call do-log,$(DYNVAR_BDIR)/makepkg.out) && \
	    mv dynvar-$(DYNVAR_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(DYNVAR_INSTDIR)
