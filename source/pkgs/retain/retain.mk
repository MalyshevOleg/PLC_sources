# Package: RETAIN
RETAIN_VERS = 1.2
RETAIN_EXT  = tar.bz2
RETAIN_PDIR = pkgs/retain
RETAIN_SITE = file://$(SOURCES_DIR)/$(RETAIN_PDIR)

RETAIN_MAKE_VARS = $(Q)PATH=$(TARGET_DIR)/bin:$$PATH
RETAIN_MAKE_TARGS = SRCDIR=$(RETAIN_SDIR)/ CC=$(TARGET)-gcc \
    LD=$(TARGET)-ld STRIP=$(TARGET)-strip strip

RETAIN_RUNTIME_INSTALL = y
RETAIN_DEPS = TOOLCHAIN

RETAIN_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) retain-rt) \
    $(call autoclean,retain-dirclean)

$(eval $(call create-common-defs,retain,RETAIN,-))

$(RETAIN_DIR)/.configured: $(RETAIN_STEPS_DIR)/.patched
	$(call print-info,[CONFG] RETAIN $(RETAIN_VERS))
	$(Q)mkdir -p $(RETAIN_BDIR) && \
	$(CP) $(RETAIN_SDIR)/Makefile $(RETAIN_BDIR)/
	$(Q)touch $@

$(RETAIN_DIR)/.hostinst: $(RETAIN_DIR)/.built
	$(Q)touch $@

retain-rt:
	$(Q){ rm -rf $(RETAIN_INSTDIR) && \
	mkdir -p $(RETAIN_INSTDIR) && \
	    cd $(RETAIN_INSTDIR) && \
	    install -d -m 755 $(RETAIN_INSTDIR)/usr/bin && \
	    install -m 755 $(RETAIN_BDIR)/rmsync \
		$(RETAIN_INSTDIR)/usr/bin/rmsync && \
	    install -m 644 $(RETAIN_SDIR)/rmsync.cfg.in \
		$(RETAIN_INSTDIR)/usr/bin/rmsync.cfg.in ; }
	$(Q)(cd $(RETAIN_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) retain-$(RETAIN_VERS).tgz \
		$(call do-log,$(RETAIN_BDIR)/makepkg.out) && \
	    mv retain-$(RETAIN_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(RETAIN_INSTDIR)
