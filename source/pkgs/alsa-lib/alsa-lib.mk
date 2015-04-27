# Package: ALSA-LIB
ALSA-LIB_VERS = 1.0.24.1
ALSA-LIB_EXT  = tar.bz2
#ALSA-LIB_SITE = ftp://ftp.alsa-project.org/pub/lib
ALSA-LIB_SITE = http://sources.buildroot.net
ALSA-LIB_PDIR = pkgs/alsa-lib

ALSA-LIB_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc
ALSA-LIB_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr \
    --libdir=/lib \
    --sysconfdir=/etc \
    --disable-python \
    --with-versioned=no \
    --enable-static

ALSA-LIB_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

ALSA-LIB_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)
ALSA-LIB_EXTRA_INSTALL = \
    $(Q)(cd $(TARGET_DIR)/$(TARGET) && \
    $(SUDO) $(CP) ./usr/share/aclocal/* ../share/aclocal/ && \
    $(SUDO) rm -rf ./usr/bin ./usr/share/aclocal && \
    $(SUDO) $(SED) -i -e 's|/lib|${TARGET_DIR}/${TARGET}/lib|' \
        lib/libasound.la `find ./lib/alsa-lib -name *.la` && \
    $(SUDO) $(SED) -i -e 's|/usr|${TARGET_DIR}/${TARGET}|' \
        -e 's|/lib|${TARGET_DIR}/${TARGET}/lib|' lib/pkgconfig/alsa.pc && \
    $(SUDO) $(CP) usr/* . && \
    $(SUDO) rm -rf ./usr ;)

ALSA-LIB_RUNTIME_INSTALL = y
ALSA-LIB_DEPS = TOOLCHAIN

ALSA-LIB_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) alsa-lib-rt) \
    $(call autoclean,alsa-lib-dirclean)

$(eval $(call create-common-defs,alsa-lib,ALSA-LIB,-))

ALSA-LIB_INSTALL_TARGET = DESTDIR=$(TARGET_DIR)/$(TARGET) install

alsa-lib-rt:
	$(Q){ rm -rf $(ALSA-LIB_INSTDIR) && \
	mkdir -p $(ALSA-LIB_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(ALSA-LIB_BDIR) program_transform_name=s!!! \
	    STRIPPROG=$(TARGET)-strip DESTDIR=$(ALSA-LIB_INSTDIR) \
	    install \
	    $(call do-log,$(ALSA-LIB_BDIR)/posthostinst.out); }
	$(Q)(cd $(ALSA-LIB_INSTDIR); rm -f lib/*.a lib/*.la; \
	    rm -f lib/alsa-lib/smixer/*.a \
		lib/alsa-lib/smixer/*.la; \
	    rm -rf usr/include lib/pkgconfig usr/share/aclocal; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so* usr/bin/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) alsa-lib-$(ALSA-LIB_VERS).tgz \
		$(call do-log,$(ALSA-LIB_BDIR)/makepkg.out) && \
	    mv alsa-lib-$(ALSA-LIB_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(ALSA-LIB_INSTDIR)
