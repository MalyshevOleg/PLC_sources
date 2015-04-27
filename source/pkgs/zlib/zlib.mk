# Package: ZLIB
ZLIB_VERS = 1.2.7
ZLIB_EXT  = tar.bz2
#ZLIB_SITE = http://www.zlib.net
ZLIB_PDIR = pkgs/zlib
ZLIB_SITE = http://pkgs.fedoraproject.org/repo/pkgs/zlib/zlib-1.2.7.tar.bz2/2ab442d169156f34c379c968f3f482dd

ZLIB_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-Os" CC=$(TARGET)-gcc RANLIB=$(TARGET)-ranlib \
    srcdir=$(ZLIB_SDIR) mandir=$(TARGET_DIR)/share/man

ZLIB_CONFIG_OPTS = \
    --shared \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib

ZLIB_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
ZLIB_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)
ZLIB_RUNTIME_INSTALL = y
ZLIB_DEPS = TOOLCHAIN

ZLIB_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) zlib-rt) \
    $(call autoclean,zlib-dirclean)

$(eval $(call create-common-defs,zlib,ZLIB,-))

zlib-rt:
	$(Q){ rm -rf $(ZLIB_INSTDIR) && \
	mkdir -p $(ZLIB_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(ZLIB_BDIR) libdir=$(ZLIB_INSTDIR)/lib \
	    install-runtime \
	    $(call do-log,$(ZLIB_BDIR)/posthostinst.out); }
	$(Q)(cd $(ZLIB_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) zlib-$(ZLIB_VERS).tgz \
		$(call do-log,$(ZLIB_BDIR)/makepkg.out) && \
	    mv zlib-$(ZLIB_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(ZLIB_INSTDIR)
