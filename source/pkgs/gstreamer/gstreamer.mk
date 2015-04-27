# Package: GSTREAMER
GSTREAMER_VERS = 0.10.32
GSTREAMER_EXT  = tar.bz2
GSTREAMER_SITE = http://gstreamer.freedesktop.org/src/gstreamer
GSTREAMER_PDIR = pkgs/gstreamer

GSTREAMER_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig
GSTREAMER_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib \
    --enable-gst-debug=yes \
    --disable-examples \
    --disable-tests \
    --enable-registry \
    --disable-loadsave \
    --disable-introspection

GSTREAMER_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

GSTREAMER_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

GSTREAMER_RUNTIME_INSTALL = y
GSTREAMER_DEPS = GLIB

GSTREAMER_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) gstreamer-rt) \
    $(call autoclean,gstreamer-dirclean)

$(eval $(call create-common-defs,gstreamer,GSTREAMER,-))

gstreamer-rt:
	$(Q){ rm -rf $(GSTREAMER_INSTDIR) && \
	mkdir -p $(GSTREAMER_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(GSTREAMER_BDIR) \
	    STRIPPROG=$(TARGET)-strip DESTDIR=$(GSTREAMER_INSTDIR) \
	    install \
	    $(call do-log,$(GSTREAMER_BDIR)/posthostinst.out); }
	$(Q)(cd $(GSTREAMER_INSTDIR)/$(TARGET_DIR)/$(TARGET); \
	    rm -f lib/*.a lib/*.la lib/gstreamer*/*.la; \
	    rm -rf include lib/pkgconfig; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so* lib/gstreamer*/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) gstreamer-$(GSTREAMER_VERS).tgz \
		$(call do-log,$(GSTREAMER_BDIR)/makepkg.out) && \
	    mv gstreamer-$(GSTREAMER_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(GSTREAMER_INSTDIR)
