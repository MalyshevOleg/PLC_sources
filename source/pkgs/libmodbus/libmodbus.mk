# Package: LIBMODBUS
LIBMODBUS_VERS = 3.0.2
LIBMODBUS_EXT  = tar.gz
LIBMODBUS_SITE = http://cloud.github.com/downloads/stephane/libmodbus
LIBMODBUS_PDIR = pkgs/libmodbus

LIBMODBUS_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os"
LIBMODBUS_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib \
    --mandir=$(TARGET_DIR)/share/man \
    --oldincludedir=$(TARGET_DIR)/$(TARGET)/include \
    --disable-static \
    --without-documentation

LIBMODBUS_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CC=$(TARGET)-gcc

LIBMODBUS_RUNTIME_INSTALL = y
LIBMODBUS_DEPS = TOOLCHAIN

LIBMODBUS_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) libmodbus-rt) \
    $(call autoclean,libmodbus-dirclean)

$(eval $(call create-common-defs,libmodbus,LIBMODBUS,-))

libmodbus-rt:
	$(Q){ rm -rf $(LIBMODBUS_INSTDIR) && \
	mkdir -p $(LIBMODBUS_INSTDIR)/lib && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(LIBMODBUS_BDIR) DESTDIR=$(LIBMODBUS_INSTDIR) libdir=/lib \
	    install-strip \
	    $(call do-log,$(LIBMODBUS_BDIR)/posthostinst.out); }
	$(Q)(cd $(LIBMODBUS_INSTDIR); \
	    rm -rf home lib/pkgconfig; rm -f lib/*.la; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) libmodbus-$(LIBMODBUS_VERS).tgz \
		$(call do-log,$(LIBMODBUS_BDIR)/makepkg.out) && \
	    mv libmodbus-$(LIBMODBUS_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(LIBMODBUS_INSTDIR)
