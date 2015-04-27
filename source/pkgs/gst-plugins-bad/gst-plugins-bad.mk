# Package: GSTPLUGINS_BAD
GSTPLUGINS_BAD_VERS = 0.10.21
GSTPLUGINS_BAD_EXT  = tar.bz2
GSTPLUGINS_BAD_SITE = http://gstreamer.freedesktop.org/src/gst-plugins-bad
GSTPLUGINS_BAD_PDIR = pkgs/gst-plugins-bad

GSTPLUGINS_BAD_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig
GSTPLUGINS_BAD_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib \
    --disable-static \
    --disable-nls \
    --disable-debug \
    --disable-examples \
    \
    --without-x \
    $(shell sed 's/\#.*$$//' "source/$(GSTPLUGINS_BAD_PDIR)/plugins.lst")

GSTPLUGINS_BAD_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

GSTPLUGINS_BAD_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

GSTPLUGINS_BAD_RUNTIME_INSTALL = y
#GSTPLUGINS_BAD_DEPS = ALSA-LIB LIBVORBIS GSTREAMER ORC
GSTPLUGINS_BAD_DEPS = GSTREAMER

GSTPLUGINS_BAD_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) gst-plugins-bad-rt) \
    $(call autoclean,gst-plugins-bad-dirclean)

$(eval $(call create-common-vars,gst-plugins-bad,GSTPLUGINS_BAD,-))
GSTPLUGINS_BAD_SRC  = gst-plugins-bad-$(GSTPLUGINS_BAD_VERS).$(GSTPLUGINS_BAD_EXT)
GSTPLUGINS_BAD_SDIR = $(PKGSOURCE_DIR)/gst-plugins-bad-$(GSTPLUGINS_BAD_VERS)
GSTPLUGINS_BAD_STEPS_DIR  = $(PKGSTEPS_DIR)/gst-plugins-bad-$(GSTPLUGINS_BAD_VERS)
GSTPLUGINS_BAD_DIR  = $(PKGBUILD_DIR)/gst-plugins-bad-$(GSTPLUGINS_BAD_VERS)
GSTPLUGINS_BAD_DL_DIR = $(DOWNLOAD_DIR)/gst-plugins-bad-$(GSTPLUGINS_BAD_VERS)
$(eval $(call create-common-targs,gst-plugins-bad,GSTPLUGINS_BAD))
$(eval $(call create-install-targs,gst-plugins-bad,GSTPLUGINS_BAD))

gst-plugins-bad-rt:
	$(Q){ rm -rf $(GSTPLUGINS_BAD_INSTDIR) && \
	mkdir -p $(GSTPLUGINS_BAD_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(GSTPLUGINS_BAD_BDIR) \
	    STRIPPROG=$(TARGET)-strip DESTDIR=$(GSTPLUGINS_BAD_INSTDIR) \
	    install \
	    $(call do-log,$(GSTPLUGINS_BAD_BDIR)/posthostinst.out); }
	$(Q)(cd $(GSTPLUGINS_BAD_INSTDIR)/$(TARGET_DIR)/$(TARGET); \
	    rm -f lib/*.a lib/*.la lib/gstreamer*/*.la; \
	    rm -rf include lib/pkgconfig; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so* lib/gstreamer*/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) gst-plugins-bad-$(GSTPLUGINS_BAD_VERS).tgz \
		$(call do-log,$(GSTPLUGINS_BAD_BDIR)/makepkg.out) && \
	    mv gst-plugins-bad-$(GSTPLUGINS_BAD_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(GSTPLUGINS_BAD_INSTDIR)
