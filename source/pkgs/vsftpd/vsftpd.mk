# Package: VSFTPD
VSFTPD_VERS = 2.3.5
VSFTPD_EXT  = tar.gz
VSFTPD_SITE = https://security.appspot.com/downloads
VSFTPD_PDIR = pkgs/vsftpd

VSFTPD_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CC=$(TARGET)-gcc
VSFTPD_MAKE_TARGS = SRCDIR=$(VSFTPD_SDIR)
VSFTPD_RUNTIME_INSTALL = y
VSFTPD_DEPS = OPENSSL

VSFTPD_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) vsftpd-rt) \
    $(call autoclean,vsftpd-dirclean)

$(eval $(call create-common-defs,vsftpd,VSFTPD,-))

$(VSFTPD_DIR)/.configured: $(VSFTPD_STEPS_DIR)/.patched
	$(call print-info,[CONFG] VSFTPD $(VSFTPD_VERS))
	$(Q)mkdir -p $(VSFTPD_BDIR) && cd $(VSFTPD_BDIR) && \
	    $(CP) $(VSFTPD_SDIR)/Makefile Makefile
	$(Q)touch $@

$(VSFTPD_DIR)/.hostinst: $(VSFTPD_DIR)/.built
	$(Q)touch $@

vsftpd-rt:
	$(Q){ rm -rf $(VSFTPD_INSTDIR) && \
	    mkdir -p $(VSFTPD_INSTDIR)/usr/sbin && \
	    $(CP) $(VSFTPD_BDIR)/vsftpd $(VSFTPD_INSTDIR)/usr/sbin && \
	    mkdir -p $(VSFTPD_INSTDIR)/etc && \
	    $(CP) $(VSFTPD_SDIR)/vsftpd.conf $(VSFTPD_INSTDIR)/etc \
	    $(call do-log,$(VSFTPD_BDIR)/posthostinst.out); }
	$(Q)(cd $(VSFTPD_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all usr/sbin/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) vsftpd-$(VSFTPD_VERS).tgz \
		$(call do-log,$(VSFTPD_BDIR)/makepkg.out) && \
	    mv vsftpd-$(VSFTPD_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(VSFTPD_INSTDIR)
