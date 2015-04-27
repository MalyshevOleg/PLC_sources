# Package: MBMASTER
MBMASTER_VERS = 2.0
MBMASTER_EXT  = tar.gz
MBMASTER_PDIR = pkgs/mbmaster
MBMASTER_SITE = file://$(SOURCES_DIR)/$(MBMASTER_PDIR)

MBMASTER_MAKE_VARS = $(Q)PATH=$(TARGET_DIR)/bin:$$PATH
MBMASTER_MAKE_TARGS = SRCDIR=$(MBMASTER_SDIR)/ CC=$(TARGET)-gcc \
    LD=$(TARGET)-ld STRIP=$(TARGET)-strip strip

MBMASTER_RUNTIME_INSTALL = y
MBMASTER_DEPS = LIBMODBUS

MBMASTER_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) mbmaster-rt) \
    $(call autoclean,mbmaster-dirclean)

$(eval $(call create-common-defs,mbmaster,MBMASTER,-))

$(MBMASTER_DIR)/.configured: $(MBMASTER_STEPS_DIR)/.patched
	$(call print-info,[CONFG] MBMASTER $(MBMASTER_VERS))
	$(Q)mkdir -p $(MBMASTER_BDIR) && \
	$(CP) $(MBMASTER_SDIR)/Makefile $(MBMASTER_BDIR)/
	$(Q)touch $@

$(MBMASTER_DIR)/.hostinst: $(MBMASTER_DIR)/.built
	$(Q)touch $@

mbmaster-rt:
	$(Q){ rm -rf $(MBMASTER_INSTDIR) && \
	mkdir -p $(MBMASTER_INSTDIR) && \
	    cd $(MBMASTER_INSTDIR) && \
	    install -d -m 755 $(MBMASTER_INSTDIR)/root && \
	    install -d -m 775 $(MBMASTER_INSTDIR)/root/mbm_state && \
	    install -m 755 $(MBMASTER_BDIR)/mb_master \
		$(MBMASTER_INSTDIR)/root/mb_master && \
	    install -m 644 $(MBMASTER_BDIR)/libmbmstrings.so \
		$(MBMASTER_INSTDIR)/root/libmbmstrings.so ; }
	$(Q)(cd $(MBMASTER_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) mbmaster-$(MBMASTER_VERS).tgz \
		$(call do-log,$(MBMASTER_BDIR)/makepkg.out) && \
	    mv mbmaster-$(MBMASTER_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(MBMASTER_INSTDIR)
