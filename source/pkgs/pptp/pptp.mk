# Package: PPTP
PPTP_VERS = 1.7.1
PPTP_EXT  = tar.gz
#PPTP_SITE = http://quozl.netrek.org/pptp
PPTP_SITE = http://quozl.linux.org.au/pptp
PPTP_PDIR = pkgs/pptp

PPTP_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CC=$(TARGET)-gcc
PPTP_MAKE_TARGS = SRCDIR=$(PPTP_SDIR) all

PPTP_RUNTIME_INSTALL = y
PPTP_DEPS = PPP

PPTP_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) pptp-rt) \
    $(call autoclean,pptp-dirclean)

$(eval $(call create-common-defs,pptp,PPTP,-))

$(PPTP_DIR)/.configured: $(PPTP_STEPS_DIR)/.patched
	$(call print-info,[CONFG] PPTP $(PPTP_VERS))
	$(Q)mkdir -p $(PPTP_BDIR) && cd $(PPTP_BDIR) && \
	    $(CP) $(PPTP_SDIR)/Makefile Makefile && \
	    $(CP) $(PPTP_SDIR)/options.pptp options.pptp
	$(Q)touch $@

$(PPTP_DIR)/.hostinst: $(PPTP_DIR)/.built
	$(Q)touch $@

pptp-rt:
	$(Q){ rm -rf $(PPTP_INSTDIR) && \
	mkdir -p $(PPTP_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH DESTDIR=$(PPTP_INSTDIR) \
	    STRIPPROG=$(TARGET)-strip \
	    $(MAKE) -C $(PPTP_BDIR) STRIP=$(TARGET)-strip \
	    install \
	    $(call do-log,$(PPTP_BDIR)/posthostinst.out); }
	$(Q)(cd $(PPTP_INSTDIR); \
	    $(TARGET)-strip usr/sbin/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) pptp-$(PPTP_VERS).tgz \
		$(call do-log,$(PPTP_BDIR)/makepkg.out) && \
	    mv pptp-$(PPTP_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(PPTP_INSTDIR)
