# Package: GST_FFMPEG
GST_FFMPEG_VERS = 0.10.13
GST_FFMPEG_EXT  = tar.bz2
GST_FFMPEG_SITE = http://gstreamer.freedesktop.org/src/gst-ffmpeg
GST_FFMPEG_PDIR = pkgs/gst-ffmpeg

GST_FFMPEG_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig
GST_FFMPEG_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib \
    --disable-static \
    $(shell sed 's/\#.*$$//' "source/$(GST_FFMPEG_PDIR)/plugins.lst")

GST_FFMPEG_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

GST_FFMPEG_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

GST_FFMPEG_RUNTIME_INSTALL = y
#GST_FFMPEG_DEPS = ALSA-LIB LIBVORBIS GSTREAMER ORC
GST_FFMPEG_DEPS = GSTREAMER LIBID3TAG LIBMAD

GST_FFMPEG_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) gst-ffmpeg-rt) \
    $(call autoclean,gst-ffmpeg-dirclean)

$(eval $(call create-common-vars,gst-ffmpeg,GST_FFMPEG,-))
GST_FFMPEG_SRC  = gst-ffmpeg-$(GST_FFMPEG_VERS).$(GST_FFMPEG_EXT)
GST_FFMPEG_SDIR = $(PKGSOURCE_DIR)/gst-ffmpeg-$(GST_FFMPEG_VERS)
GST_FFMPEG_STEPS_DIR  = $(PKGSTEPS_DIR)/gst-ffmpeg-$(GST_FFMPEG_VERS)
GST_FFMPEG_DIR  = $(PKGBUILD_DIR)/gst-ffmpeg-$(GST_FFMPEG_VERS)
GST_FFMPEG_DL_DIR = $(DOWNLOAD_DIR)/gst-ffmpeg-$(GST_FFMPEG_VERS)
$(eval $(call create-common-targs,gst-ffmpeg,GST_FFMPEG))
$(eval $(call create-install-targs,gst-ffmpeg,GST_FFMPEG))

gst-ffmpeg-rt:
	$(Q){ rm -rf $(GST_FFMPEG_INSTDIR) && \
	mkdir -p $(GST_FFMPEG_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(GST_FFMPEG_BDIR) \
	    STRIPPROG=$(TARGET)-strip DESTDIR=$(GST_FFMPEG_INSTDIR) \
	    install \
	    $(call do-log,$(GST_FFMPEG_BDIR)/posthostinst.out); }
	$(Q)(cd $(GST_FFMPEG_INSTDIR)/$(TARGET_DIR)/$(TARGET); \
	    rm -f lib/*.a lib/*.la lib/gstreamer*/*.la; \
	    rm -rf include lib/pkgconfig; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so* lib/gstreamer*/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) gst-ffmpeg-$(GST_FFMPEG_VERS).tgz \
		$(call do-log,$(GST_FFMPEG_BDIR)/makepkg.out) && \
	    mv gst-ffmpeg-$(GST_FFMPEG_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(GST_FFMPEG_INSTDIR)
