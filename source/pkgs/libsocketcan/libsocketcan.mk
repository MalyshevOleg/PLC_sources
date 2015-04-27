# Package: LIBSOCKETCAN
LIBSOCKETCAN_VERS = 0.0.9
LIBSOCKETCAN_EXT  = tar.bz2
LIBSOCKETCAN_SITE = http://www.pengutronix.de/software/libsocketcan/download
LIBSOCKETCAN_PDIR = pkgs/libsocketcan

LIBSOCKETCAN_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os" \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig

LIBSOCKETCAN_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib \
    --mandir=$(TARGET_DIR)/share/man \
    --oldincludedir=$(TARGET_DIR)/$(TARGET)/include

LIBSOCKETCAN_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CC=$(TARGET)-gcc
LIBSOCKETCAN_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

LIBSOCKETCAN_RUNTIME_INSTALL = y
LIBSOCKETCAN_DEPS = TOOLCHAIN

LIBSOCKETCAN_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) libsocketcan-rt) \
    $(call autoclean,libsocketcan-dirclean)

$(eval $(call create-common-defs,libsocketcan,LIBSOCKETCAN,-))

libsocketcan-rt:
	$(Q){ rm -rf $(LIBSOCKETCAN_INSTDIR) && \
	mkdir -p $(LIBSOCKETCAN_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(LIBSOCKETCAN_BDIR) DESTDIR=$(LIBSOCKETCAN_INSTDIR) \
	    install \
	    $(call do-log,$(LIBSOCKETCAN_BDIR)/posthostinst.out); }
	$(Q)(cd $(LIBSOCKETCAN_INSTDIR)/$(TARGET_DIR)/$(TARGET); \
	    rm -f lib/*.la; rm -rf include lib/pkgconfig; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) libsocketcan-$(LIBSOCKETCAN_VERS).tgz \
		$(call do-log,$(LIBSOCKETCAN_BDIR)/makepkg.out) && \
	    mv libsocketcan-$(LIBSOCKETCAN_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(LIBSOCKETCAN_INSTDIR)
