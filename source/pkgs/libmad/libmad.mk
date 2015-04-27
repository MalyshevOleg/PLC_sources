# Package: LZO
LIBMAD_VERS = 0.15.1b
LIBMAD_EXT  = tar.gz
LIBMAD_SITE = ftp://ftp.mars.org/pub/mpeg/
LIBMAD_PDIR = pkgs/libmad

LIBMAD_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os"
LIBMAD_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR)/$(TARGET) \
    --bindir=$(TARGET_DIR)/bin \
    --disable-static \
    --enable-shared

LIBMAD_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CC=$(TARGET)-gcc
LIBMAD_MAKE_TARGS = all
LIBMAD_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)
LIBMAD_RUNTIME_INSTALL = y
LIBMAD_DEPS = TOOLCHAIN libid3tag

LIBMAD_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) libmad-rt) \
    $(call autoclean,libmad-dirclean)

$(eval $(call create-common-defs,libmad,LIBMAD,-))

libmad-rt:
	$(Q){ rm -rf $(LIBMAD_INSTDIR) && \
	mkdir -p $(LIBMAD_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(LIBMAD_BDIR) DESTDIR=$(LIBMAD_INSTDIR) \
	    prefix=/usr bindir=/usr/bin datarootdir=/usr/share \
	    install \
	    $(call do-log,$(LIBMAD_BDIR)/posthostinst.out); }
	$(Q)(cd $(LIBMAD_INSTDIR); \
	    rm -f usr/lib/*.a usr/lib/*.la; \
	    rm -rf usr/include usr/share; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) libmad-$(LIBMAD_VERS).tgz \
		$(call do-log,$(LIBMAD_BDIR)/makepkg.out) && \
	    mv libmad-$(LIBMAD_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(LIBMAD_INSTDIR)
