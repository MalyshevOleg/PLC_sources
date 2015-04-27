# Package: APCUPSD
APCUPSD_VERS = 3.14.9
APCUPSD_EXT  = tar.gz
APCUPSD_SITE = http://downloads.sourceforge.net/apcupsd
APCUPSD_PDIR = pkgs/apcupsd

APCUPSD_CONFIG_VARS = cd $(APCUPSD_BDIR) && lndir $(APCUPSD_SDIR) > /dev/null && \
    PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os" \
    RANLIB=$(TARGET_DIR)/bin/$(TARGET)-ranlib \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig
APCUPSD_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr

APCUPSD_MAKE_VARS = $(Q)PATH=$(TARGET_DIR)/bin:$$PATH

APCUPSD_RUNTIME_INSTALL = y
APCUPSD_DEPS = TOOLCHAIN

APCUPSD_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) apcupsd-rt) \
    $(call autoclean,apcupsd-dirclean)

$(eval $(call create-common-defs,apcupsd,APCUPSD,-))

$(APCUPSD_DIR)/.hostinst: $(APCUPSD_DIR)/.built
	$(Q)touch $@

apcupsd-rt:
	$(Q){ rm -rf $(APCUPSD_INSTDIR )&& \
	mkdir -p $(APCUPSD_INSTDIR) && \
	    cd $(APCUPSD_INSTDIR) && \
	    install -d -m 755 $(APCUPSD_INSTDIR)/usr/sbin && \
	    install -m 755 $(APCUPSD_BDIR)/src/apcupsd \
		$(APCUPSD_INSTDIR)/usr/sbin/apcupsd && \
	    install -m 755 $(APCUPSD_BDIR)/src/apcaccess \
		$(APCUPSD_INSTDIR)/usr/sbin/apcaccess && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip $(APCUPSD_INSTDIR)/usr/sbin/* ; }
	$(Q)(cd $(APCUPSD_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) apcupsd-$(APCUPSD_VERS).tgz \
		$(call do-log,$(APCUPSD_BDIR)/makepkg.out) && \
	    mv apcupsd-$(APCUPSD_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(APCUPSD_INSTDIR)
