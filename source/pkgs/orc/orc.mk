# Package: ORC
ORC_VERS = 0.4.16
ORC_EXT  = tar.gz
ORC_SITE = http://code.entropywave.com/download/orc
ORC_PDIR = pkgs/orc

ORC_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig
ORC_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib \
    --disable-static \
    --disable-gtk-doc \
    --disable-gtk-doc-html \
    --disable-gtk-doc-pdf \
    --enable-backend=arm

ORC_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

ORC_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

ORC_RUNTIME_INSTALL = y
ORC_DEPS = TOOLCHAIN

ORC_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) orc-rt) \
    $(call autoclean,orc-dirclean)

$(eval $(call create-common-defs,orc,ORC,-))

ORC_INSTALL_TARGET = SUBDIRS="orc orc-test" install

orc-rt:
	$(Q){ rm -rf $(ORC_INSTDIR) && \
	mkdir -p $(ORC_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(ORC_BDIR) \
	    SUBDIRS="orc orc-test" DESTDIR=$(ORC_INSTDIR) \
	    install-strip \
	    $(call do-log,$(ORC_BDIR)/posthostinst.out); }
	$(Q)(cd $(ORC_INSTDIR)/$(TARGET_DIR)/$(TARGET); \
	    rm -f lib/*.a lib/*.la ; \
	    rm -rf include lib/pkgconfig; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) orc-$(ORC_VERS).tgz \
		$(call do-log,$(ORC_BDIR)/makepkg.out) && \
	    mv orc-$(ORC_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(ORC_INSTDIR)
