# Package: STUNNEL
STUNNEL_VERS = 4.33
STUNNEL_EXT  = tar.gz
#STUNNEL_SITE = http://www.stunnel.org/download/stunnel/src
STUNNEL_SITE = ftp://ftp.stunnel.org/stunnel/archive/4.x
STUNNEL_PDIR = pkgs/stunnel

STUNNEL_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-Os" CC=$(TARGET)-gcc \
    ac_cv_file___dev_ptmx_=yes \
    ac_cv_file___dev_ptc_=no
STUNNEL_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr \
    --with-random=/dev/urandom \
    --with-ssl=$(TARGET_DIR)/$(TARGET)

STUNNEL_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

STUNNEL_RUNTIME_INSTALL = y
STUNNEL_DEPS = OPENSSL

STUNNEL_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) stunnel-rt) \
    $(call autoclean,stunnel-dirclean)

$(eval $(call create-common-defs,stunnel,STUNNEL,-))

$(STUNNEL_DIR)/.hostinst: $(STUNNEL_DIR)/.built
	$(Q)touch $@

stunnel-rt:
	$(Q){ rm -rf $(STUNNEL_INSTDIR) && \
	mkdir -p $(STUNNEL_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH DESTDIR=$(STUNNEL_INSTDIR) \
	    $(MAKE) -C $(STUNNEL_BDIR) openssl=openssl \
	    install \
	    $(call do-log,$(STUNNEL_BDIR)/posthostinst.out); }
	$(Q)(cd $(STUNNEL_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) stunnel-$(STUNNEL_VERS).tgz \
		$(call do-log,$(STUNNEL_BDIR)/makepkg.out) && \
	    mv stunnel-$(STUNNEL_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(STUNNEL_INSTDIR)
