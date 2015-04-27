# Package: GSTPLUGINS_UGLY
GSTPLUGINS_UGLY_VERS = 0.10.18
GSTPLUGINS_UGLY_EXT  = tar.bz2
GSTPLUGINS_UGLY_SITE = http://gstreamer.freedesktop.org/src/gst-plugins-ugly
GSTPLUGINS_UGLY_PDIR = pkgs/gst-plugins-ugly

GSTPLUGINS_UGLY_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig
GSTPLUGINS_UGLY_CONFIG_OPTS = \
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
    $(shell sed 's/\#.*$$//' "source/$(GSTPLUGINS_UGLY_PDIR)/plugins.lst")

GSTPLUGINS_UGLY_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

GSTPLUGINS_UGLY_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

GSTPLUGINS_UGLY_RUNTIME_INSTALL = y
#GSTPLUGINS_UGLY_DEPS = ALSA-LIB LIBVORBIS GSTREAMER ORC
GSTPLUGINS_UGLY_DEPS = GSTREAMER

GSTPLUGINS_UGLY_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) gst-plugins-ugly-rt) \
    $(call autoclean,gst-plugins-ugly-dirclean)

$(eval $(call create-common-vars,gst-plugins-ugly,GSTPLUGINS_UGLY,-))
GSTPLUGINS_UGLY_SRC  = gst-plugins-ugly-$(GSTPLUGINS_UGLY_VERS).$(GSTPLUGINS_UGLY_EXT)
GSTPLUGINS_UGLY_SDIR = $(PKGSOURCE_DIR)/gst-plugins-ugly-$(GSTPLUGINS_UGLY_VERS)
GSTPLUGINS_UGLY_STEPS_DIR  = $(PKGSTEPS_DIR)/gst-plugins-ugly-$(GSTPLUGINS_UGLY_VERS)
GSTPLUGINS_UGLY_DIR  = $(PKGBUILD_DIR)/gst-plugins-ugly-$(GSTPLUGINS_UGLY_VERS)
GSTPLUGINS_UGLY_DL_DIR = $(DOWNLOAD_DIR)/gst-plugins-ugly-$(GSTPLUGINS_UGLY_VERS)
$(eval $(call create-common-targs,gst-plugins-ugly,GSTPLUGINS_UGLY))
$(eval $(call create-install-targs,gst-plugins-ugly,GSTPLUGINS_UGLY))

gst-plugins-ugly-rt:
	$(Q){ rm -rf $(GSTPLUGINS_UGLY_INSTDIR) && \
	mkdir -p $(GSTPLUGINS_UGLY_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(GSTPLUGINS_UGLY_BDIR) \
	    STRIPPROG=$(TARGET)-strip DESTDIR=$(GSTPLUGINS_UGLY_INSTDIR) \
	    install \
	    $(call do-log,$(GSTPLUGINS_UGLY_BDIR)/posthostinst.out); }
	$(Q)(cd $(GSTPLUGINS_UGLY_INSTDIR)/$(TARGET_DIR)/$(TARGET); \
	    rm -f lib/*.a lib/*.la lib/gstreamer*/*.la; \
	    rm -rf include lib/pkgconfig; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so* lib/gstreamer*/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) gst-plugins-ugly-$(GSTPLUGINS_UGLY_VERS).tgz \
		$(call do-log,$(GSTPLUGINS_UGLY_BDIR)/makepkg.out) && \
	    mv gst-plugins-ugly-$(GSTPLUGINS_UGLY_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(GSTPLUGINS_UGLY_INSTDIR)
