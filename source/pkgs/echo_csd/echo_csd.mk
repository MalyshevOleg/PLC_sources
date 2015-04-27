# Package: ECHO_CSD
ECHO_CSD_VERS = 1.0
ECHO_CSD_EXT  = tar.bz2
ECHO_CSD_PDIR = pkgs/echo_csd
ECHO_CSD_SITE = file://$(SOURCES_DIR)/$(ECHO_CSD_PDIR)

ECHO_CSD_MAKE_VARS = $(Q)PATH=$(TARGET_DIR)/bin:$$PATH
ECHO_CSD_MAKE_TARGS = SRCDIR=$(ECHO_CSD_SDIR) CC=$(TARGET)-gcc \
    LD=$(TARGET)-ld STRIP=$(TARGET)-strip strip

ECHO_CSD_RUNTIME_INSTALL = y
ECHO_CSD_DEPS = TOOLCHAIN

ECHO_CSD_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) echo_csd-rt) \
    $(call autoclean,echo_csd-dirclean)

$(eval $(call create-common-defs,echo_csd,ECHO_CSD,-))

$(ECHO_CSD_DIR)/.configured: $(ECHO_CSD_STEPS_DIR)/.patched
	$(call print-info,[CONFG] ECHO_CSD $(ECHO_CSD_VERS))
	$(Q)mkdir -p $(ECHO_CSD_BDIR) && \
	$(CP) $(ECHO_CSD_SDIR)/Makefile $(ECHO_CSD_BDIR)/
	$(Q)touch $@

$(ECHO_CSD_DIR)/.hostinst: $(ECHO_CSD_DIR)/.built
	$(Q)touch $@

echo_csd-rt:
	$(Q){ rm -rf $(ECHO_CSD_INSTDIR) && \
	mkdir -p $(ECHO_CSD_INSTDIR) && \
	    cd $(ECHO_CSD_INSTDIR) && \
	    install -d -m 755 $(ECHO_CSD_INSTDIR)/usr/bin && \
	    install -m 755 $(ECHO_CSD_BDIR)/echo_csd \
		$(ECHO_CSD_INSTDIR)/usr/bin/echo_csd && \
	    install -m 644 $(ECHO_CSD_SDIR)/chat_init \
		$(ECHO_CSD_INSTDIR)/usr/bin/chat_init ; }
	$(Q)(cd $(ECHO_CSD_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) echo_csd-$(ECHO_CSD_VERS).tgz \
		$(call do-log,$(ECHO_CSD_BDIR)/makepkg.out) && \
	    mv echo_csd-$(ECHO_CSD_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(ECHO_CSD_INSTDIR)
