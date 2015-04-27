# Package: LZO
LZO_VERS = 2.06
LZO_EXT  = tar.gz
LZO_SITE = http://www.oberhumer.com/opensource/lzo/download
LZO_PDIR = pkgs/lzo

LZO_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os"
LZO_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR)/$(TARGET) \
    --bindir=$(TARGET_DIR)/bin \
    --disable-static \
    --enable-shared

LZO_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CC=$(TARGET)-gcc
LZO_MAKE_TARGS = all
LZO_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)
LZO_RUNTIME_INSTALL = y
LZO_DEPS = TOOLCHAIN

LZO_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) lzo-rt) \
    $(call autoclean,lzo-dirclean)

$(eval $(call create-common-defs,lzo,LZO,-))

lzo-rt:
	$(Q){ rm -rf $(LZO_INSTDIR) && \
	mkdir -p $(LZO_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(LZO_BDIR) DESTDIR=$(LZO_INSTDIR) \
	    prefix=/usr bindir=/usr/bin datarootdir=/usr/share \
	    install \
	    $(call do-log,$(LZO_BDIR)/posthostinst.out); }
	$(Q)(cd $(LZO_INSTDIR); \
	    rm -f usr/lib/*.a usr/lib/*.la; \
	    rm -rf usr/include usr/share; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) lzo-$(LZO_VERS).tgz \
		$(call do-log,$(LZO_BDIR)/makepkg.out) && \
	    mv lzo-$(LZO_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(LZO_INSTDIR)
