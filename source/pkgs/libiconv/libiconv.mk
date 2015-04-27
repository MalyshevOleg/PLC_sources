# Package: LIBICONV
LIBICONV_VERS = 1.14
LIBICONV_EXT  = tar.gz
LIBICONV_SITE = http://ftp.gnu.org/pub/gnu/libiconv
LIBICONV_PDIR = pkgs/libiconv

LIBICONV_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os"
LIBICONV_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib \
    --mandir=$(TARGET_DIR)/share/man \
    --oldincludedir=$(TARGET_DIR)/$(TARGET)/include \
    --disable-static

LIBICONV_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CC=$(TARGET)-gcc
LIBICONV_MAKE_TARGS = all

LIBICONV_RUNTIME_INSTALL = y
LIBICONV_DEPS = TOOLCHAIN

LIBICONV_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) libiconv-rt) \
    $(call autoclean,libiconv-dirclean)

$(eval $(call create-common-defs,libiconv,LIBICONV,-))

LIBICONV_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)
LIBICONV_INSTALL_TARGET = install-lib

libiconv-rt:
	$(Q){ rm -rf $(LIBICONV_INSTDIR) && \
	mkdir -p $(LIBICONV_INSTDIR)/lib && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(LIBICONV_BDIR) libdir=$(LIBICONV_INSTDIR)/lib \
	    includedir=$(LIBICONV_INSTDIR)/include install-lib \
	    $(call do-log,$(LIBICONV_BDIR)/posthostinst.out); }
	$(Q)(cd $(LIBICONV_INSTDIR); \
	    rm -f lib/*.a lib/*la; \
	    rm -rf include; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) libiconv-$(LIBICONV_VERS).tgz \
		$(call do-log,$(LIBICONV_BDIR)/makepkg.out) && \
	    mv libiconv-$(LIBICONV_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(LIBICONV_INSTDIR)
