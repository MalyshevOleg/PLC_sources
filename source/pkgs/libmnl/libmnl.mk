#http://www.netfilter.org/projects/libmnl/files/libmnl-1.0.3.tar.bz2
LIBMNL_VERS = 1.0.3
LIBMNL_EXT  = tar.bz2
LIBMNL_SITE = http://www.netfilter.org/projects/libmnl/files/
LIBMNL_PDIR = pkgs/libmnl

LIBMNL_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os"
LIBMNL_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR)/$(TARGET) \
    --bindir=$(TARGET_DIR)/bin \
    --disable-static \
    --enable-shared

LIBMNL_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CC=$(TARGET)-gcc
LIBMNL_MAKE_TARGS = all
LIBMNL_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)
LIBMNL_RUNTIME_INSTALL = y
LIBMNL_DEPS = TOOLCHAIN

LIBMNL_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) libmnl-rt) \
    $(call autoclean,libmnl-dirclean)

$(eval $(call create-common-defs,libmnl,LIBMNL,-))

libmnl-rt:
	$(Q){ rm -rf $(LIBMNL_INSTDIR) && \
	mkdir -p $(LIBMNL_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(LIBMNL_BDIR) DESTDIR=$(LIBMNL_INSTDIR) \
	    prefix=/usr libdir=/lib bindir=/usr/bin \
	    install \
	    $(call do-log,$(LIBMNL_BDIR)/posthostinst.out); }
	$(Q)(cd $(LIBMNL_INSTDIR); \
	    rm -f lib/*.a lib/*.la; \
	    rm -rf usr lib/pkgconfig; \
	    $(TARGET)-strip --strip-all lib/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) libmnl-$(LIBMNL_VERS).tgz \
		$(call do-log,$(LIBMNL_BDIR)/makepkg.out) && \
	    mv libmnl-$(LIBMNL_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(LIBMNL_INSTDIR)
