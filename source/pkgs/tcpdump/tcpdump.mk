#http://www.tcpdump.org/release/tcpdump-4.7.3.tar.gz
TCPDUMP_VERS = 4.7.3
TCPDUMP_EXT  = tar.gz
TCPDUMP_SITE = http://www.tcpdump.org/release
TCPDUMP_PDIR = pkgs/tcpdump

TCPDUMP_CFLAGS=CFLAGS="-O2" CC=$(TARGET)-gcc CPP=$(TARGET)-cpp

TCPDUMP_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    $(TCPDUMP_CFLAGS) \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig

TCPDUMP_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --libdir=/lib \
    --prefix=/usr

TCPDUMP_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
TCPDUMP_RUNTIME_INSTALL = y
TCPDUMP_DEPS = TOOLCHAIN


TCPDUMP_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) tcpdump-rt) \
    $(call autoclean,tcpdump-dirclean)


$(eval $(call create-common-defs,tcpdump,TCPDUMP,-))

TCPDUMP_INSTALL_TARGET = PATH=$(TARGET_DIR)/bin:$$PATH DESTDIR=$(TARGET_DIR)/$(TARGET) install


tcpdump-rt:
	$(Q){ rm -rf $(TCPDUMP_INSTDIR) && \
	mkdir -p $(TCPDUMP_INSTDIR) && \
	    COMPILER_PATH=$(TARGET_DIR)/bin $(TCPDUMP_CFLAGS) \
	    $(MAKE) -C $(TCPDUMP_BDIR) STRIPPROG=$(TARGET)-strip DESTDIR=$(TCPDUMP_INSTDIR) install \
	    $(call do-log,$(TCPDUMP_BDIR)/posthostinst.out); }
	$(Q)(cd $(TCPDUMP_INSTDIR); rm -f lib/*.a lib/*.la; \
	    rm -rf usr/include lib/pkgconfig usr/share/aclocal usr/share; \
		rm usr/sbin/tcpdump.$(TCPDUMP_VERS); \
		$(TARGET)-strip --strip-all usr/sbin/*; \
		$(MAKEPKG) tcpdump-$(TCPDUMP_VERS).tgz \
		$(call do-log,$(TCPDUMP_BDIR)/makepkg.out) && \
	    mv tcpdump-$(TCPDUMP_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(TCPDUMP_INSTDIR)
