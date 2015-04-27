# Package: WEBCONFIG
WEBCONFIG_VERS = 1.6
WEBCONFIG_EXT  = tar.bz2
WEBCONFIG_PDIR = pkgs/webconfig
WEBCONFIG_SITE = file://$(SOURCES_DIR)/$(WEBCONFIG_PDIR)

WEBCONFIG_MAKE_VARS = $(Q)PATH=$(TARGET_DIR)/bin:$$PATH
WEBCONFIG_MAKE_TARGS = SRCDIR=$(WEBCONFIG_SDIR)/wc CC=$(TARGET)-gcc \
    CROSS_COMPILE= STRIP=$(TARGET)-strip PLC=$(WEBCONFIG_DEF) \
    LD=$(TARGET)-ld ranlib=$(TARGET)-ranlib strip

WEBCONFIG_RUNTIME_INSTALL = y
WEBCONFIG_DEPS = TOOLCHAIN

WEBCONFIG_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) webconfig-rt) \
    $(call autoclean,webconfig-dirclean)

$(eval $(call create-common-defs,webconfig,WEBCONFIG,-))

WEBCONFIG_BDIR=$(WEBCONFIG_DIR)/build-$(BUILDCONF)

$(WEBCONFIG_DIR)/.configured: $(WEBCONFIG_STEPS_DIR)/.patched
	$(call print-info,[CONFG] WEBCONFIG $(WEBCONFIG_VERS))
	$(Q)mkdir -p $(WEBCONFIG_BDIR) && \
	$(CP) $(WEBCONFIG_SDIR)/wc/Makefile $(WEBCONFIG_BDIR)/
	$(Q)touch $@

$(WEBCONFIG_DIR)/.hostinst: $(WEBCONFIG_DIR)/.built
	$(Q)touch $@

webconfig-rt:
	$(Q){ rm -rf $(WEBCONFIG_INSTDIR) && \
	mkdir -p $(WEBCONFIG_INSTDIR) && \
	    cd $(WEBCONFIG_INSTDIR) && \
	    install -d -m 755 $(WEBCONFIG_INSTDIR)/www/cgi && \
	    (if [ -f $(WEBCONFIG_BDIR)/wc_version.inc ]; then \
		install -m 644 $(WEBCONFIG_BDIR)/wc_version.inc \
		    $(WEBCONFIG_INSTDIR)/www/cgi/wc_version.inc; fi) && \
	    install -m 755 $(WEBCONFIG_BDIR)/setup.cgi \
		$(WEBCONFIG_INSTDIR)/www/cgi/setup.cgi && \
	    tar cp -C $(WEBCONFIG_SDIR)/www . | \
		(cd $(WEBCONFIG_INSTDIR)/www; tar xp); }
	$(Q)(cd $(WEBCONFIG_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) webconfig-$(WEBCONFIG_VERS).tgz \
		$(call do-log,$(WEBCONFIG_BDIR)/makepkg.out) && \
	    mv webconfig-$(WEBCONFIG_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(WEBCONFIG_INSTDIR)
