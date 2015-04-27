# Package: DROPBEAR
DROPBEAR_VERS = 2012.55
DROPBEAR_EXT  = tar.bz2
DROPBEAR_SITE = http://matt.ucc.asn.au/dropbear/releases
DROPBEAR_PDIR = pkgs/dropbear

DROPBEAR_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os"
DROPBEAR_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --with-shared \
    --disable-nls

DROPBEAR_MAKE_VARS = $(Q)PATH=$(TARGET_DIR)/bin:$$PATH
DROPBEAR_MAKE_TARGS = \
    PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" \
    MULTI=1 SCPPROGRESS=1

DROPBEAR_RUNTIME_INSTALL = y
DROPBEAR_DEPS = ZLIB

DROPBEAR_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) dropbear-rt) \
    $(call autoclean,dropbear-dirclean)

$(eval $(call create-common-defs,dropbear,DROPBEAR,-))

$(DROPBEAR_DIR)/.hostinst: $(DROPBEAR_DIR)/.built
	$(Q)touch $@

dropbear-rt:
	$(Q){ rm -rf $(DROPBEAR_INSTDIR ) && \
	mkdir -p $(DROPBEAR_INSTDIR) && \
	    cd $(DROPBEAR_INSTDIR) && \
	    install -d -m 755 $(DROPBEAR_INSTDIR)/usr/sbin && \
	    install -d -m 755 $(DROPBEAR_INSTDIR)/usr/bin && \
	    install -m 755 $(DROPBEAR_BDIR)/dropbearmulti \
		$(DROPBEAR_INSTDIR)/usr/sbin/dropbear && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip $(DROPBEAR_INSTDIR)/usr/sbin/dropbear && \
	    ln -snf ../sbin/dropbear $(DROPBEAR_INSTDIR)/usr/bin/scp && \
	    ln -snf ../sbin/dropbear $(DROPBEAR_INSTDIR)/usr/bin/ssh && \
	    ln -snf ../sbin/dropbear $(DROPBEAR_INSTDIR)/usr/bin/dbclient && \
	    ln -snf ../sbin/dropbear $(DROPBEAR_INSTDIR)/usr/bin/dropbearkey && \
	    ln -snf ../sbin/dropbear $(DROPBEAR_INSTDIR)/usr/bin/dropbearconvert && \
	    mkdir -p $(DROPBEAR_INSTDIR)/etc/dropbear && \
	    $(CP) $(DROPBEAR_SDIR)/S50dropbear \
		$(DROPBEAR_INSTDIR)/etc/rc.dropbear && \
	    chmod a+x $(DROPBEAR_INSTDIR)/etc/rc.dropbear; }
	$(Q)(cd $(DROPBEAR_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) dropbear-$(DROPBEAR_VERS).tgz \
		$(call do-log,$(DROPBEAR_BDIR)/makepkg.out) && \
	    mv dropbear-$(DROPBEAR_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(DROPBEAR_INSTDIR)
