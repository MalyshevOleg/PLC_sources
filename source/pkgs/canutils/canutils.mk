# Package: CANUTILS
CANUTILS_VERS = 4.0.6
CANUTILS_EXT  = tar.bz2
CANUTILS_SITE = http://www.pengutronix.de/software/socket-can/download/canutils/v4.0
CANUTILS_PDIR = pkgs/canutils

CANUTILS_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-Os" CC=$(TARGET)-gcc \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig
  
CANUTILS_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr

CANUTILS_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

CANUTILS_RUNTIME_INSTALL = y
CANUTILS_DEPS = LIBSOCKETCAN

CANUTILS_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) canutils-rt) \
    $(call autoclean,canutils-dirclean)

$(eval $(call create-common-defs,canutils,CANUTILS,-))

$(CANUTILS_DIR)/.hostinst: $(CANUTILS_DIR)/.built
	$(Q)touch $@

canutils-rt:
	$(Q){ rm -rf $(CANUTILS_INSTDIR) && \
	    mkdir -p $(CANUTILS_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(CANUTILS_BDIR) DESTDIR=$(CANUTILS_INSTDIR) \
	    install \
	    $(call do-log,$(CANUTILS_BDIR)/posthostinst.out); }
	$(Q){ cd $(CANUTILS_INSTDIR); rm -rf usr/lib usr/share; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all usr/bin/* usr/sbin/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) canutils-$(CANUTILS_VERS).tgz \
		$(call do-log,$(CANUTILS_BDIR)/makepkg.out) && \
	    mv canutils-$(CANUTILS_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;}
	$(Q)rm -rf $(CANUTILS_INSTDIR)
