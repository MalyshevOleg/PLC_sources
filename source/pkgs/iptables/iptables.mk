# Package: IPTABLES
IPTABLES_VERS = 1.4.21
IPTABLES_EXT  = tar.bz2
IPTABLES_SITE = http://www.netfilter.org/projects/iptables/files
IPTABLES_PDIR = pkgs/iptables

IPTABLES_CFLAGS=CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc CPP=$(TARGET)-cpp

IPTABLES_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    $(IPTABLES_CFLAGS) \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig

IPTABLES_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --oldincludedir=$(TARGET_DIR)/$(TARGET)/include \
    --with-kernel="$(LINUX_SDIR)" \
    --libdir=/lib \
    --sysconfdir=/etc \
    --disable-ipv6 \
    --prefix=/usr

IPTABLES_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
IPTABLES_RUNTIME_INSTALL = y
IPTABLES_DEPS = TOOLCHAIN


IPTABLES_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) iptables-rt) \
    $(call autoclean,iptables-dirclean)


$(eval $(call create-common-defs,iptables,IPTABLES,-))

IPTABLES_INSTALL_TARGET = PATH=$(TARGET_DIR)/bin:$$PATH DESTDIR=$(TARGET_DIR)/$(TARGET) install

$(IPTABLES_BDIR)/.configured: $(TOOLCHAIN_DIR)/.headers

iptables-rt:
	$(Q){ rm -rf $(IPTABLES_INSTDIR) && \
	mkdir -p $(IPTABLES_INSTDIR) && \
	    COMPILER_PATH=$(TARGET_DIR)/bin $(IPTABLES_CFLAGS) \
	    $(MAKE) -C $(IPTABLES_BDIR) STRIPPROG=$(TARGET)-strip DESTDIR=$(IPTABLES_INSTDIR) install \
	    $(call do-log,$(IPTABLES_BDIR)/posthostinst.out); }
	$(Q)(cd $(IPTABLES_INSTDIR); rm -f lib/*.a lib/*.la; \
	    rm -rf usr/include lib/pkgconfig usr/share/aclocal usr/share; \
		$(TARGET)-strip --strip-all lib/*so* usr/bin/*; \
		$(MAKEPKG) iptables-$(IPTABLES_VERS).tgz \
		$(call do-log,$(IPTABLES_BDIR)/makepkg.out) && \
	    mv iptables-$(IPTABLES_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(IPTABLES_INSTDIR)
