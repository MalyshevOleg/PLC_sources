# Package: GSTPLUGINS_GOOD
GSTPLUGINS_GOOD_VERS = 0.10.28
GSTPLUGINS_GOOD_EXT  = tar.bz2
GSTPLUGINS_GOOD_SITE = http://gstreamer.freedesktop.org/src/gst-plugins-good
GSTPLUGINS_GOOD_PDIR = pkgs/gst-plugins-good

GSTPLUGINS_GOOD_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig
GSTPLUGINS_GOOD_CONFIG_OPTS = \
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
    \
    --without-libv4l2 \
    --without-x \
    --without-gudev \
    $(shell sed 's/\#.*$$//' "source/$(GSTPLUGINS_GOOD_PDIR)/plugins.lst")

#source/$(GSTPLUGINS_GOOD_PDIR)/gst-plugins-good.mk: source/$(GSTPLUGINS_GOOD_PDIR)/plugins.lst

GSTPLUGINS_GOOD_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

GSTPLUGINS_GOOD_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

GSTPLUGINS_GOOD_RUNTIME_INSTALL = y
#GSTPLUGINS_GOOD_DEPS = ALSA-LIB LIBVORBIS GSTREAMER ORC
GSTPLUGINS_GOOD_DEPS = GSTREAMER ORC

GSTPLUGINS_GOOD_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) gst-plugins-good-rt) \
    $(call autoclean,gst-plugins-good-dirclean)

$(eval $(call create-common-vars,gst-plugins-good,GSTPLUGINS_GOOD,-))
GSTPLUGINS_GOOD_SRC  = gst-plugins-good-$(GSTPLUGINS_GOOD_VERS).$(GSTPLUGINS_GOOD_EXT)
GSTPLUGINS_GOOD_SDIR = $(PKGSOURCE_DIR)/gst-plugins-good-$(GSTPLUGINS_GOOD_VERS)
GSTPLUGINS_GOOD_STEPS_DIR  = $(PKGSTEPS_DIR)/gst-plugins-good-$(GSTPLUGINS_GOOD_VERS)
GSTPLUGINS_GOOD_DIR  = $(PKGBUILD_DIR)/gst-plugins-good-$(GSTPLUGINS_GOOD_VERS)
GSTPLUGINS_GOOD_DL_DIR = $(DOWNLOAD_DIR)/gst-plugins-good-$(GSTPLUGINS_GOOD_VERS)
$(eval $(call create-common-targs,gst-plugins-good,GSTPLUGINS_GOOD))
$(eval $(call create-install-targs,gst-plugins-good,GSTPLUGINS_GOOD))

gst-plugins-good-rt:
	$(Q){ rm -rf $(GSTPLUGINS_GOOD_INSTDIR) && \
	mkdir -p $(GSTPLUGINS_GOOD_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(GSTPLUGINS_GOOD_BDIR) \
	    STRIPPROG=$(TARGET)-strip DESTDIR=$(GSTPLUGINS_GOOD_INSTDIR) \
	    install \
	    $(call do-log,$(GSTPLUGINS_GOOD_BDIR)/posthostinst.out); }
	$(Q)(cd $(GSTPLUGINS_GOOD_INSTDIR)/$(TARGET_DIR)/$(TARGET); \
	    rm -f lib/*.a lib/*.la lib/gstreamer*/*.la; \
	    rm -rf include lib/pkgconfig; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so* lib/gstreamer*/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) gst-plugins-good-$(GSTPLUGINS_GOOD_VERS).tgz \
		$(call do-log,$(GSTPLUGINS_GOOD_BDIR)/makepkg.out) && \
	    mv gst-plugins-good-$(GSTPLUGINS_GOOD_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(GSTPLUGINS_GOOD_INSTDIR)
