#http://www.tcpdump.org/release/libpcap-1.7.2.tar.gz
LIBPCAP_VERS = 1.7.2
LIBPCAP_EXT  = tar.gz
LIBPCAP_SITE = http://www.tcpdump.org/release/
LIBPCAP_PDIR = pkgs/libpcap

LIBPCAP_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os"
LIBPCAP_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR)/$(TARGET) \
    --bindir=$(TARGET_DIR)/bin \
    --disable-static \
    --enable-shared \
    --with-pcap=linux

LIBPCAP_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CC=$(TARGET)-gcc
LIBPCAP_MAKE_TARGS = all
LIBPCAP_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)
LIBPCAP_RUNTIME_INSTALL = y
LIBPCAP_DEPS = TOOLCHAIN

LIBPCAP_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) libpcap-rt) \
    $(call autoclean,libpcap-dirclean)

$(eval $(call create-common-defs,libpcap,LIBPCAP,-))

libpcap-rt:
	$(Q){ rm -rf $(LIBPCAP_INSTDIR) && \
	mkdir -p $(LIBPCAP_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(LIBPCAP_BDIR) DESTDIR=$(LIBPCAP_INSTDIR) \
	    prefix=/usr libdir=/lib bindir=/usr/bin \
	    install \
	    $(call do-log,$(LIBPCAP_BDIR)/posthostinst.out); }
	$(Q)(cd $(LIBPCAP_INSTDIR); \
	    rm -f lib/*.a lib/*.la; \
	    rm -rf usr lib/pkgconfig; \
	    $(TARGET)-strip --strip-all lib/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) libpcap-$(LIBPCAP_VERS).tgz \
		$(call do-log,$(LIBPCAP_BDIR)/makepkg.out) && \
	    mv libpcap-$(LIBPCAP_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(LIBPCAP_INSTDIR)
