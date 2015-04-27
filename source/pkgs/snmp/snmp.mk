# Package: SNMP
SNMP_VERS = 5.6.1.1
SNMP_EXT  = tar.gz
SNMP_SITE = ftp://mirror.ancl.hawaii.edu/pub/NetBSD/packages/distfiles/
#SNMP_SITE = http://downloads.sourceforge.net/project/net-snmp/net-snmp/$(SNMP_VERS)
#SNMP_SITE = http://mirror.transact.net.au/sourceforge/n/project/ne/net-snmp/net-snmp/5.6.2.1/
SNMP_PDIR = pkgs/snmp

SNMP_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig
SNMP_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/ \
    --sysconfdir=/etc \
    --datarootdir=/usr/share \
    --oldincludedir=$(TARGET_DIR)/$(TARGET)/include \
    --with-defaults \
    --enable-agentx-dom-sock-only \
    --without-rpm \
    --disable-debugging \
    --disable-embedded-perl \
    --disable-manuals \
    --disable-scripts \
    --disable-static

SNMP_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

SNMP_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)
SNMP_EXTRA_INSTALL = \
    $(Q)(cd $(TARGET_DIR)/$(TARGET)/lib && \
    $(SUDO) $(SED) -i -e 's|//lib|${TARGET_DIR}/${TARGET}/lib|g' \
        libnetsnmp*.la)

SNMP_RUNTIME_INSTALL = y
SNMP_DEPS = OPENSSL

SNMP_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) snmp-rt) \
    $(call autoclean,snmp-dirclean)

$(eval $(call create-common-vars,snmp,SNMP,-))
SNMP_SRC  = net-snmp-$(SNMP_VERS).$(SNMP_EXT)
SNMP_SDIR = $(PKGSOURCE_DIR)/net-snmp-$(SNMP_VERS)
SNMP_DIR  = $(PKGBUILD_DIR)/snmp-$(SNMP_VERS)
SNMP_DL_DIR = $(DOWNLOAD_DIR)/net-snmp-$(SNMP_VERS)
$(eval $(call create-common-targs,snmp,SNMP))
$(eval $(call create-install-targs,snmp,SNMP))

SNMP_INSTALL_TARGET = DESTDIR=$(TARGET_DIR)/$(TARGET) \
    bindir=/../bin \
    INSTALLBINSCRIPTS=net-snmp-config \
    installheaders installlibs installlocalbin

snmp-rt:
	$(Q){ rm -rf $(SNMP_INSTDIR) && \
	mkdir -p $(SNMP_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(SNMP_BDIR) \
	    STRIPPROG=$(TARGET)-strip DESTDIR=$(SNMP_INSTDIR) \
	    install \
	    $(call do-log,$(SNMP_BDIR)/posthostinst.out); }
	$(Q)(cd $(SNMP_INSTDIR); \
	    rm -f lib/*.a lib/*.la bin/net-snmp-config; \
	    rm -rf include lib/pkgconfig; \
	    mkdir -p etc/snmp; cp $(SNMP_PATCH_DIR)/snmpd.conf etc/snmp ; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so* sbin/* bin/[^n]*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) snmp-$(SNMP_VERS).tgz \
		$(call do-log,$(SNMP_BDIR)/makepkg.out) && \
	    mv snmp-$(SNMP_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(SNMP_INSTDIR)
