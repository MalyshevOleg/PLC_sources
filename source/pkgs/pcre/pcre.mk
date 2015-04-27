# Package: PCRE
PCRE_VERS = 8.31
PCRE_EXT  = tar.bz2
PCRE_SITE = http://sourceforge.net/projects/pcre/files/pcre/$(PCRE_VERS)
PCRE_PDIR = pkgs/pcre

PCRE_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os" \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig

PCRE_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib \
    --mandir=$(TARGET_DIR)/share/man \
    --oldincludedir=$(TARGET_DIR)/$(TARGET)/include \
    --disable-static \
    --enable-newline-is-anycrlf \
    --enable-utf8

PCRE_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CC=$(TARGET)-gcc

PCRE_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

PCRE_RUNTIME_INSTALL = y
PCRE_DEPS = TOOLCHAIN

PCRE_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) pcre-rt) \
    $(call autoclean,pcre-dirclean)

$(eval $(call create-common-defs,pcre,PCRE,-))

PCRE_INSTALL_TARGET = install-libLTLIBRARIES \
    install-includeHEADERS install-binSCRIPTS

pcre-rt:
	$(Q){ rm -rf $(PCRE_INSTDIR) && \
	mkdir -p $(PCRE_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(PCRE_BDIR) DESTDIR=$(PCRE_INSTDIR) \
	    install \
	    $(call do-log,$(PCRE_BDIR)/posthostinst.out); }
	$(Q)(cd $(PCRE_INSTDIR)/$(TARGET_DIR)/$(TARGET); \
	    rm -f lib/*.la; rm -rf include lib/pkgconfig; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) pcre-$(PCRE_VERS).tgz \
		$(call do-log,$(PCRE_BDIR)/makepkg.out) && \
	    mv pcre-$(PCRE_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(PCRE_INSTDIR)
