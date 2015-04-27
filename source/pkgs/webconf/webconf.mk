# Package: WEBCONF
WEBCONF_VERS = 1.0
WEBCONF_EXT  = tar.gz
WEBCONF_PDIR = pkgs/webconf
WEBCONF_SITE = file://$(SOURCES_DIR)/$(WEBCONF_PDIR)

WEBCONF_RUNTIME_INSTALL = y
WEBCONF_DEPS = TOOLCHAIN

WEBCONF_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
WEBCONF_MAKE_TARGS = CROSSPATH= CROSS_PREFIX=$(TARGET)- SDIR=$(WEBCONF_SDIR)

WEBCONF_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) webconf-rt) \
    $(call autoclean,webconf-dirclean)

$(eval $(call create-common-defs,webconf,WEBCONF,-))

$(WEBCONF_DIR)/.configured: $(WEBCONF_STEPS_DIR)/.patched
	$(call print-info,configuring WEBCONF $(WEBCONF_VERS))
	$(Q)mkdir -p $(WEBCONF_BDIR) && \
	    $(CP) $(WEBCONF_SDIR)/Makefile $(WEBCONF_BDIR)/Makefile
	$(Q)touch $@

$(WEBCONF_DIR)/.hostinst: $(WEBCONF_DIR)/.built
	$(Q)touch $@

webconf-rt:
	$(Q){ rm -rf $(WEBCONF_INSTDIR )&& mkdir -p $(WEBCONF_INSTDIR) && \
	    cd $(WEBCONF_INSTDIR) && \
	    install -d -m 755 $(WEBCONF_INSTDIR)/usr/sbin && \
	    install -m 755 $(WEBCONF_BDIR)/setup.cgi \
		$(WEBCONF_INSTDIR)/usr/sbin/setup.cgi ; }
	$(Q)(cd $(WEBCONF_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) webconf-$(WEBCONF_VERS).tgz \
		$(call do-log,$(WEBCONF_BDIR)/makepkg.out) && \
	    mv webconf-$(WEBCONF_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(WEBCONF_INSTDIR)
