# Package: THTTPD
THTTPD_VERS = 2.25b
THTTPD_EXT  = tar.gz
THTTPD_SITE = http://ftp.debian.org/debian/pool/main/t/thttpd
THTTPD_PDIR = pkgs/thttpd

THTTPD_CONFIG_VARS =  cd $(THTTPD_BDIR) && lndir $(THTTPD_SDIR) > /dev/null && \
    PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-Os" CC=$(TARGET)-gcc
THTTPD_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr

THTTPD_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

THTTPD_RUNTIME_INSTALL = y
THTTPD_DEPS = TOOLCHAIN

THTTPD_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) thttpd-rt) \
    $(call autoclean,thttpd-dirclean)

$(eval $(call create-common-vars,thttpd,THTTPD,_))
THTTPD_SRC=thttpd_$(THTTPD_VERS).orig.$(THTTPD_EXT)
THTTPD_SDIR=$(PKGSOURCE_DIR)/thttpd-$(THTTPD_VERS)
THTTPD_DIR=$(PKGBUILD_DIR)/thttpd-$(THTTPD_VERS)
THTTPD_DL_DIR=$(DOWNLOAD_DIR)/thttpd-$(THTTPD_VERS)
$(eval $(call create-common-targs,thttpd,THTTPD))
$(eval $(call create-install-targs,thttpd,THTTPD))

$(THTTPD_DIR)/.hostinst: $(THTTPD_DIR)/.built
	$(Q)touch $@

thttpd-rt:
	$(Q){ rm -rf $(THTTPD_INSTDIR) && \
	mkdir -p $(THTTPD_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH DESTDIR=$(THTTPD_INSTDIR) \
	    $(MAKE) -C $(THTTPD_BDIR) \
	    installthis \
	    $(call do-log,$(THTTPD_BDIR)/posthostinst.out); }
	$(Q)(cd $(THTTPD_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all usr/sbin/thttpd; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) thttpd-$(THTTPD_VERS).tgz \
		$(call do-log,$(THTTPD_BDIR)/makepkg.out) && \
	    mv thttpd-$(THTTPD_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(THTTPD_INSTDIR)
