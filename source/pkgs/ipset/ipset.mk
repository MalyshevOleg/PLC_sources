# Package: IPSET
IPSET_VERS = 6.24
IPSET_EXT  = tar.bz2
IPSET_SITE = http://ipset.netfilter.org/
IPSET_PDIR = pkgs/ipset

IPSET_CFLAGS=CFLAGS="-O2" CC=$(TARGET)-gcc

IPSET_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    $(IPSET_CFLAGS) \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig

IPSET_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --with-ksource="$(LINUX_SDIR)" \
    --with-kbuild="$(LINUX_BDIR)" \
    --prefix=/usr

IPSET_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
IPSET_RUNTIME_INSTALL = y
IPSET_DEPS = LIBMNL

IPSET_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) ipset-rt) \
    $(call autoclean,ipset-dirclean)

$(eval $(call create-common-defs,ipset,IPSET,-))

IPSET_INSTALL_TARGET = PATH=$(TARGET_DIR)/bin:$$PATH DESTDIR=$(TARGET_DIR)/$(TARGET) install

$(IPSET_DIR)/.configured: $(LINUX_DIR)/.compiled $(IPSET_STEPS_DIR)/.patched
	$(call print-info,[CONFG] IPSET $(IPSET_VERS))
	$(Q)mkdir -p $(IPSET_BDIR) && cd $(IPSET_BDIR) && \
	    $(IPSET_CONFIG_VARS) \
	    $(IPSET_SDIR)/$(CONFIGURE) $(IPSET_CONFIG_OPTS) \
	    $(call do-log,$(IPSET_BDIR)/configure.out)
	$(Q)touch $@

$(IPSET_DIR)/.hostinst: $(IPSET_DIR)/.built
	$(Q)touch $@

ipset-rt:
	$(Q){ rm -rf $(IPSET_INSTDIR) && \
	mkdir -p $(IPSET_INSTDIR) && \
	    COMPILER_PATH=$(TARGET_DIR)/bin $(IPSET_CFLAGS) \
	    $(MAKE) -C $(IPSET_BDIR) STRIPPROG=$(TARGET)-strip DESTDIR=$(IPSET_INSTDIR) libdir=/lib install \
	    $(call do-log,$(IPSET_BDIR)/posthostinst.out); }
	$(Q)(cd $(IPSET_INSTDIR); rm -rf usr/share lib/*.la lib/*.a lib/pkgconfig usr/include; \
		$(TARGET)-strip --strip-all usr/sbin/* lib/*; \
		$(MAKEPKG) ipset-$(IPSET_VERS).tgz \
		$(call do-log,$(IPSET_BDIR)/makepkg.out) && \
	    mv ipset-$(IPSET_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(IPSET_INSTDIR)

#install -m 0755 $(SOURCES_DIR)/$(IPSET_PDIR)/files/ip2range usr/bin; \
