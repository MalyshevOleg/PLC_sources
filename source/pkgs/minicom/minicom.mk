# Package: MINICOM
MINICOM_VERS = 2.6
MINICOM_EXT  = tar.gz
MINICOM_SITE = http://alioth.debian.org/frs/download.php/file/3689
MINICOM_PDIR = pkgs/minicom

MINICOM_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-O2" \
    oldincludedir=$(TARGET_DIR)/$(TARGET)/include
MINICOM_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --disable-rpath \
    --disable-nls

MINICOM_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

MINICOM_RUNTIME_INSTALL = y
MINICOM_DEPS = ZLIB

MINICOM_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) minicom-rt) \
    $(call autoclean,minicom-dirclean)

$(eval $(call create-common-defs,minicom,MINICOM,-))

$(MINICOM_DIR)/.hostinst: $(MINICOM_DIR)/.built
	$(Q)touch $@

minicom-rt:
	$(Q){ rm -rf $(MINICOM_INSTDIR) && \
	mkdir -p $(MINICOM_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKE) -C $(MINICOM_BDIR) DESTDIR=$(MINICOM_INSTDIR) \
		install-strip \
	    $(call do-log,$(MINICOM_BDIR)/posthostinst.out); }
	$(Q)(cd $(MINICOM_INSTDIR); \
	    rm -rf usr/share; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) minicom-$(MINICOM_VERS).tgz \
		$(call do-log,$(MINICOM_BDIR)/makepkg.out) && \
	    mv minicom-$(MINICOM_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(MINICOM_INSTDIR)
