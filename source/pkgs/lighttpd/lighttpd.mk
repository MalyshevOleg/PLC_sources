# Package: LIGHTTPD
LIGHTTPD_VERS = 1.4.31
LIGHTTPD_EXT  = tar.bz2
LIGHTTPD_SITE = http://download.lighttpd.net/lighttpd/releases-1.4.x
LIGHTTPD_PDIR = pkgs/lighttpd

LIGHTTPD_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os"
LIGHTTPD_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr \
    --disable-ipv6 \
    --disable-static \
    --without-bzip2 \
    --without-webdav-props \
    --without-webdav-locks \
    --with-openssl \
    --with-pcre \
    --with-zlib

LIGHTTPD_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

LIGHTTPD_RUNTIME_INSTALL = y
LIGHTTPD_DEPS = ZLIB PCRE

LIGHTTPD_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) lighttpd-rt) \
    $(call autoclean,lighttpd-dirclean)

$(eval $(call create-common-defs,lighttpd,LIGHTTPD,-))

$(LIGHTTPD_DIR)/.hostinst: $(LIGHTTPD_DIR)/.built
	$(Q)touch $@

lighttpd-rt:
	$(Q){ rm -rf $(LIGHTTPD_INSTDIR) && \
	mkdir -p $(LIGHTTPD_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH DESTDIR=$(LIGHTTPD_INSTDIR) \
	    $(MAKE) -C $(LIGHTTPD_BDIR) program_transform_name=s!!! \
	    install \
	    $(call do-log,$(LIGHTTPD_BDIR)/posthostinst.out); }
	$(Q)(cd $(LIGHTTPD_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all usr/sbin/*; \
	    mkdir -p etc/lighttpd; \
	    $(CP) -a $(LIGHTTPD_SDIR)/doc/config/conf.d etc/lighttpd; \
	    $(CP) $(LIGHTTPD_SDIR)/doc/config/*.conf  etc/lighttpd; \
	    rm -f usr/lib/*.la etc/lighttpd/conf.d/Make* && rm -rf usr/share; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) lighttpd-$(LIGHTTPD_VERS).tgz \
		$(call do-log,$(LIGHTTPD_BDIR)/makepkg.out) && \
	    mv lighttpd-$(LIGHTTPD_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(LIGHTTPD_INSTDIR)
