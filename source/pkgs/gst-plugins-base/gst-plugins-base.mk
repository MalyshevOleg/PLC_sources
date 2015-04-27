# Package: GSTPLUGINS_BASE
GSTPLUGINS_BASE_VERS = 0.10.32
GSTPLUGINS_BASE_EXT  = tar.bz2
GSTPLUGINS_BASE_SITE = http://gstreamer.freedesktop.org/src/gst-plugins-base
GSTPLUGINS_BASE_PDIR = pkgs/gst-plugins-base

GSTPLUGINS_BASE_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig
GSTPLUGINS_BASE_CONFIG_OPTS = \
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
    --disable-x \
    --disable-xvideo \
    --disable-xshm \
    --disable-oggtest \
    --disable-vorbistest \
    --disable-freetypetest \
    --disable-libvisual \
    --disable-pango \
    --disable-introspection \
    --disable-theora

GSTPLUGINS_BASE_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

GSTPLUGINS_BASE_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

GSTPLUGINS_BASE_RUNTIME_INSTALL = y
GSTPLUGINS_BASE_DEPS = ALSA-LIB LIBVORBIS GSTREAMER ORC

GSTPLUGINS_BASE_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) gst-plugins-base-rt) \
    $(call autoclean,gst-plugins-base-dirclean)

$(eval $(call create-common-vars,gst-plugins-base,GSTPLUGINS_BASE,-))
GSTPLUGINS_BASE_SRC  = gst-plugins-base-$(GSTPLUGINS_BASE_VERS).$(GSTPLUGINS_BASE_EXT)
GSTPLUGINS_BASE_SDIR = $(PKGSOURCE_DIR)/gst-plugins-base-$(GSTPLUGINS_BASE_VERS)
GSTPLUGINS_BASE_STEPS_DIR  = $(PKGSTEPS_DIR)/gst-plugins-base-$(GSTPLUGINS_BASE_VERS)
GSTPLUGINS_BASE_DIR  = $(PKGBUILD_DIR)/gst-plugins-base-$(GSTPLUGINS_BASE_VERS)
GSTPLUGINS_BASE_DL_DIR = $(DOWNLOAD_DIR)/gst-plugins-base-$(GSTPLUGINS_BASE_VERS)
$(eval $(call create-common-targs,gst-plugins-base,GSTPLUGINS_BASE))
$(eval $(call create-install-targs,gst-plugins-base,GSTPLUGINS_BASE))

gst-plugins-base-rt:
	$(Q){ rm -rf $(GSTPLUGINS_BASE_INSTDIR) && \
	mkdir -p $(GSTPLUGINS_BASE_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(GSTPLUGINS_BASE_BDIR) \
	    STRIPPROG=$(TARGET)-strip DESTDIR=$(GSTPLUGINS_BASE_INSTDIR) \
	    install \
	    $(call do-log,$(GSTPLUGINS_BASE_BDIR)/posthostinst.out); }
	$(Q)(cd $(GSTPLUGINS_BASE_INSTDIR)/$(TARGET_DIR)/$(TARGET); \
	    rm -f lib/*.a lib/*.la lib/gstreamer*/*.la; \
	    rm -rf include lib/pkgconfig; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so* lib/gstreamer*/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) gst-plugins-base-$(GSTPLUGINS_BASE_VERS).tgz \
		$(call do-log,$(GSTPLUGINS_BASE_BDIR)/makepkg.out) && \
	    mv gst-plugins-base-$(GSTPLUGINS_BASE_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(GSTPLUGINS_BASE_INSTDIR)
