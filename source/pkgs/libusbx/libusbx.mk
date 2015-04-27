LIBUSBX_VERS = 1.0.18
LIBUSBX_EXT  = tar.bz2
LIBUSBX_SITE = http://downloads.sourceforge.net/project/libusbx/releases/$(LIBUSBX_VERS)/source/
LIBUSBX_PDIR = pkgs/libusbx

LIBUSBX_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
                      CFLAGS="-O2" CC=$(TARGET)-gcc
LIBUSBX_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/ \
    --libdir=/lib \
    --disable-udev \
    --enable-share

LIBUSBX_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
LIBUSBX_DEPS = TOOLCHAIN

LIBUSBX_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

LIBUSBX_RUNTIME_INSTALL = y

$(eval $(call create-common-defs,libusbx,LIBUSBX,-))

LIBUSBX_INSTALL_TARGET = DESTDIR=$(TARGET_DIR)/$(TARGET) install

LIBUSBX_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) libusbx-rt) \
                        $(call autoclean,libusbx-dirclean)

libusbx-rt:
	$(Q){	rm -rf $(LIBUSBX_INSTDIR) && \
	      	mkdir -p $(LIBUSBX_INSTDIR) && \
		$(MAKE) -C $(LIBUSBX_BDIR) STRIPPROG=$(TARGET)-strip DESTDIR=$(LIBUSBX_INSTDIR) install \
		$(call do-log,$(LIBUSBX_BDIR)/posthostinst.out); }
	$(Q)(	cd $(LIBUSBX_INSTDIR); rm -f lib/*.a lib/*.la; \
	    	rm -rf usr lib/pkgconfig include; \
		$(TARGET)-strip --strip-all lib/*so*; \
		$(MAKEPKG) libusbx-$(LIBUSBX_VERS).tgz \
		$(call do-log,$(LIBUSBX_BDIR)/makepkg.out) && \
	         mv libusbx-$(LIBUSBX_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(LIBUSBX_INSTDIR)
