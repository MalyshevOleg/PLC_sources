# Package: LIBXML2
LIBXML2_VERS = 2.7.8
LIBXML2_EXT  = tar.gz
LIBXML2_SITE = ftp://xmlsoft.org/libxml2
LIBXML2_PDIR = pkgs/libxml2

LIBXML2_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os"
LIBXML2_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib \
    --mandir=$(TARGET_DIR)/share/man \
    --oldincludedir=$(TARGET_DIR)/$(TARGET)/include \
    --without-python \
    --disable-static \
    --enable-ipv6=no

LIBXML2_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CC=$(TARGET)-gcc
LIBXML2_MAKE_TARGS = all

LIBXML2_RUNTIME_INSTALL = y
LIBXML2_DEPS = TOOLCHAIN

LIBXML2_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) libxml2-rt) \
    $(call autoclean,libxml2-dirclean)

$(eval $(call create-common-defs,libxml2,LIBXML2,-))

LIBXML2_INSTALL_TARGET = bin_PROGRAMS= install

libxml2-rt:
	$(Q){ rm -rf $(LIBXML2_INSTDIR) && \
	mkdir -p $(LIBXML2_INSTDIR)/lib && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(LIBXML2_BDIR) DESTDIR=$(LIBXML2_INSTDIR) libdir=/lib \
	    install-libLTLIBRARIES \
	    $(call do-log,$(LIBXML2_BDIR)/posthostinst.out); }
	$(Q)(cd $(LIBXML2_INSTDIR); \
	    rm -f lib/*.a lib/*la; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) libxml2-$(LIBXML2_VERS).tgz \
		$(call do-log,$(LIBXML2_BDIR)/makepkg.out) && \
	    mv libxml2-$(LIBXML2_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(LIBXML2_INSTDIR)
