# Package: LIBOGG
LIBOGG_VERS = 1.3.0
LIBOGG_EXT  = tar.gz
LIBOGG_SITE = http://downloads.xiph.org/releases/ogg
LIBOGG_PDIR = pkgs/libogg

LIBOGG_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os"
LIBOGG_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib \
    --mandir=$(TARGET_DIR)/share/man \
    --oldincludedir=$(TARGET_DIR)/$(TARGET)/include \
    --disable-static

LIBOGG_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CC=$(TARGET)-gcc

LIBOGG_RUNTIME_INSTALL = y
LIBOGG_DEPS = TOOLCHAIN

LIBOGG_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) libogg-rt) \
    $(call autoclean,libogg-dirclean)

$(eval $(call create-common-defs,libogg,LIBOGG,-))

libogg-rt:
	$(Q){ rm -rf $(LIBOGG_INSTDIR) && \
	mkdir -p $(LIBOGG_INSTDIR)/lib && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(LIBOGG_BDIR) DESTDIR=$(LIBOGG_INSTDIR) libdir=/lib \
	    install-strip \
	    $(call do-log,$(LIBOGG_BDIR)/posthostinst.out); }
	$(Q)(cd $(LIBOGG_INSTDIR); \
	    rm -rf home lib/pkgconfig; rm -f lib/*.la; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) libogg-$(LIBOGG_VERS).tgz \
		$(call do-log,$(LIBOGG_BDIR)/makepkg.out) && \
	    mv libogg-$(LIBOGG_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(LIBOGG_INSTDIR)
