# Package: WHATMASK
WHATMASK_VERS = 1.2
WHATMASK_EXT  = tar.gz
WHATMASK_SITE = http://downloads.laffeycomputer.com/current_builds/whatmask
WHATMASK_PDIR = pkgs/whatmask

WHATMASK_CFLAGS=CFLAGS="-O2" CC=$(TARGET)-gcc

WHATMASK_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    $(WHATMASK_CFLAGS) \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig

WHATMASK_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr

WHATMASK_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
WHATMASK_RUNTIME_INSTALL = y
WHATMASK_DEPS = TOOLCHAIN

WHATMASK_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) whatmask-rt) \
    $(call autoclean,whatmask-dirclean)

$(eval $(call create-common-defs,whatmask,WHATMASK,-))

WHATMASK_INSTALL_TARGET = PATH=$(TARGET_DIR)/bin:$$PATH DESTDIR=$(TARGET_DIR)/$(TARGET) install

$(WHATMASK_DIR)/.hostinst: $(WHATMASK_DIR)/.built
	$(Q)touch $@

whatmask-rt:
	$(Q){ rm -rf $(WHATMASK_INSTDIR) && \
	mkdir -p $(WHATMASK_INSTDIR) && \
	    COMPILER_PATH=$(TARGET_DIR)/bin $(WHATMASK_CFLAGS) \
	    $(MAKE) -C $(WHATMASK_BDIR) STRIPPROG=$(TARGET)-strip DESTDIR=$(WHATMASK_INSTDIR) install \
	    $(call do-log,$(WHATMASK_BDIR)/posthostinst.out); }
	$(Q)(cd $(WHATMASK_INSTDIR); rm -rf usr/man; \
		$(TARGET)-strip --strip-all usr/bin/*; \
		$(MAKEPKG) whatmask-$(WHATMASK_VERS).tgz \
		$(call do-log,$(WHATMASK_BDIR)/makepkg.out) && \
	    mv whatmask-$(WHATMASK_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(WHATMASK_INSTDIR)

#install -m 0755 $(SOURCES_DIR)/$(WHATMASK_PDIR)/files/ip2range usr/bin; \
