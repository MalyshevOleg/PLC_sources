# Package: FREETYPE
FREETYPE_VERS = 2.5.4
FREETYPE_EXT  = tar.bz2
#FREETYPE_SITE = ftp://ftp.alsa-project.org/pub/lib
FREETYPE_SITE = http://download.savannah.gnu.org/releases/freetype/
FREETYPE_PDIR = pkgs/freetype

FREETYPE_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc
FREETYPE_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr \
    --libdir=/lib \
    --sysconfdir=/etc 

FREETYPE_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

FREETYPE_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)


FREETYPE_RUNTIME_INSTALL = y
FREETYPE_DEPS = TOOLCHAIN

FREETYPE_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) freetype-rt) \
    $(call autoclean,freetype-dirclean)

$(eval $(call create-common-defs,freetype,FREETYPE,-))

FREETYPE_INSTALL_TARGET = DESTDIR=$(TARGET_DIR)/$(TARGET) install

freetype-rt:
	$(Q){ rm -rf $(FREETYPE_INSTDIR) && \
	mkdir -p $(FREETYPE_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(FREETYPE_BDIR) program_transform_name=s!!! \
	    STRIPPROG=$(TARGET)-strip DESTDIR=$(FREETYPE_INSTDIR) \
	    install \
	    $(call do-log,$(FREETYPE_BDIR)/posthostinst.out); }
	$(Q)(cd $(FREETYPE_INSTDIR); rm -f lib/*.a lib/*.la; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so* usr/bin/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) freetype-$(FREETYPE_VERS).tgz \
		$(call do-log,$(FREETYPE_BDIR)/makepkg.out) && \
	    mv freetype-$(FREETYPE_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(FREETYPE_INSTDIR)
