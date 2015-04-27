# Package: LIBNL
LIBNL_VERS = 3.2.21
LIBNL_EXT  = tar.gz
LIBNL_SITE = http://www.infradead.org/~tgr/libnl/files/
LIBNL_PDIR = pkgs/libnl

LIBNL_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2" CC=$(TARGET)-gcc

LIBNL_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/ \
    --sysconfdir=/etc \
    --libdir=/lib \
    --enable-shared \
    --disable-static \
    --disable-cli

LIBNL_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

LIBNL_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

LIBNL_RUNTIME_INSTALL = y
LIBNL_DEPS = TOOLCHAIN

LIBNL_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) libnl-rt) \
    $(call autoclean,libnl-dirclean)

$(eval $(call create-common-defs,libnl,LIBNL,-))

LIBNL_INSTALL_TARGET = DESTDIR=$(TARGET_DIR)/$(TARGET) install

libnl-rt:
	$(Q){ rm -rf $(LIBNL_INSTDIR) && \
	mkdir -p $(LIBNL_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(LIBNL_BDIR) DESTDIR=$(LIBNL_INSTDIR) \
	    install \
	    $(call do-log,$(LIBNL_BDIR)/posthostinst.out); }
	$(Q)(cd $(LIBNL_INSTDIR)/; \
            rm -rf etc share include; \
	    rm -f lib/*.a lib/*.la; \
	    rm -rf lib/pkgconfig; \
	    rm -rf include share ; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) libnl-$(LIBNL_VERS).tgz \
		$(call do-log,$(LIBNL_BDIR)/makepkg.out) && \
	    mv libnl-$(LIBNL_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(LIBNL_INSTDIR)
