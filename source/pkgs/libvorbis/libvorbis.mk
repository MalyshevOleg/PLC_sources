# Package: LIBVORBIS
LIBVORBIS_VERS = 1.3.2
LIBVORBIS_EXT  = tar.bz2
LIBVORBIS_SITE = http://downloads.xiph.org/releases/vorbis
LIBVORBIS_PDIR = pkgs/libvorbis

LIBVORBIS_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os" \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig

LIBVORBIS_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib \
    --mandir=$(TARGET_DIR)/share/man \
    --oldincludedir=$(TARGET_DIR)/$(TARGET)/include \
    --disable-static \
    --disable-docs \
    --disable-examples

LIBVORBIS_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CC=$(TARGET)-gcc
LIBVORBIS_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

LIBVORBIS_RUNTIME_INSTALL = y
LIBVORBIS_DEPS = LIBOGG

LIBVORBIS_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) libvorbis-rt) \
    $(call autoclean,libvorbis-dirclean)

$(eval $(call create-common-defs,libvorbis,LIBVORBIS,-))

libvorbis-rt:
	$(Q){ rm -rf $(LIBVORBIS_INSTDIR) && \
	mkdir -p $(LIBVORBIS_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(LIBVORBIS_BDIR) DESTDIR=$(LIBVORBIS_INSTDIR) \
	    install \
	    $(call do-log,$(LIBVORBIS_BDIR)/posthostinst.out); }
	$(Q)(cd $(LIBVORBIS_INSTDIR)/$(TARGET_DIR)/$(TARGET); \
	    rm -f lib/*.la; rm -rf include lib/pkgconfig; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) libvorbis-$(LIBVORBIS_VERS).tgz \
		$(call do-log,$(LIBVORBIS_BDIR)/makepkg.out) && \
	    mv libvorbis-$(LIBVORBIS_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(LIBVORBIS_INSTDIR)
