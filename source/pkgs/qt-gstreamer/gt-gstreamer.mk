# Package: QT-GSTREAMER
QT-GSTREAMER_VERS = 0.10.1
QT-GSTREAMER_EXT  = tar.bz2
#QT-GSTREAMER_SITE = ftp://ftp.alsa-project.org/pub/lib
QT-GSTREAMER_SITE = http://sources.buildroot.net
QT-GSTREAMER_PDIR = pkgs/qt-gstreamer

QT-GSTREAMER_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc
QT-GSTREAMER_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr \
    --libdir=/lib \
    --sysconfdir=/etc \
    --disable-python \
    --with-versioned=no \
    --enable-static

QT-GSTREAMER_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

QT-GSTREAMER_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)
QT-GSTREAMER_EXTRA_INSTALL = \
    $(Q)(cd $(TARGET_DIR)/$(TARGET) && \
    $(SUDO) $(CP) ./usr/share/aclocal/* ../share/aclocal/ && \
    $(SUDO) rm -rf ./usr/bin ./usr/share/aclocal && \
    $(SUDO) $(SED) -i -e 's|/lib|${TARGET_DIR}/${TARGET}/lib|' \
        lib/libasound.la `find ./lib/qt-gstreamer -name *.la` && \
    $(SUDO) $(SED) -i -e 's|/usr|${TARGET_DIR}/${TARGET}|' \
        -e 's|/lib|${TARGET_DIR}/${TARGET}/lib|' lib/pkgconfig/alsa.pc && \
    $(SUDO) $(CP) usr/* . && \
    $(SUDO) rm -rf ./usr ;)

QT-GSTREAMER_RUNTIME_INSTALL = y
QT-GSTREAMER_DEPS = TOOLCHAIN

QT-GSTREAMER_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) qt-gstreamer-rt) \
    $(call autoclean,qt-gstreamer-dirclean)

$(eval $(call create-common-defs,qt-gstreamer,QT-GSTREAMER,-))

QT-GSTREAMER_INSTALL_TARGET = DESTDIR=$(TARGET_DIR)/$(TARGET) install

qt-gstreamer-rt:
	$(Q){ rm -rf $(QT-GSTREAMER_INSTDIR) && \
	mkdir -p $(QT-GSTREAMER_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(QT-GSTREAMER_BDIR) program_transform_name=s!!! \
	    STRIPPROG=$(TARGET)-strip DESTDIR=$(QT-GSTREAMER_INSTDIR) \
	    install \
	    $(call do-log,$(QT-GSTREAMER_BDIR)/posthostinst.out); }
	$(Q)(cd $(QT-GSTREAMER_INSTDIR); rm -f lib/*.a lib/*.la; \
	    rm -f lib/qt-gstreamer/smixer/*.a \
		lib/qt-gstreamer/smixer/*.la; \
	    rm -rf usr/include lib/pkgconfig usr/share/aclocal; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so* usr/bin/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) qt-gstreamer-$(QT-GSTREAMER_VERS).tgz \
		$(call do-log,$(QT-GSTREAMER_BDIR)/makepkg.out) && \
	    mv qt-gstreamer-$(QT-GSTREAMER_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(QT-GSTREAMER_INSTDIR)
