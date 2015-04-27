# Package: NTP
NTP_VERS = 4.2.6p5
NTP_EXT  = tar.gz
NTP_SITE = http://archive.ntp.org/ntp4/ntp-4.2
NTP_PDIR = pkgs/ntp

NTP_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    lo_cv_with_autoopts_config=no \
    lo_cv_test_autoopts=no
NTP_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr \
    --localstatedir=/var \
    --sysconfdir=/etc \
    --bindir=/usr/sbin \
    --sbindir=/usr/sbin \
    --mandir=/usr/man \
    --program-prefix= \
    --program-suffix= \
    --enable-parse-clocks \
    --enable-debugging \
    --enable-debug-timing \
    --disable-local-libopts \
    --disable-dependency-tracking \
    --enable-NMEA \
    --with-sntp=no

NTP_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

NTP_RUNTIME_INSTALL = y
NTP_DEPS = TOOLCHAIN

NTP_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) ntp-rt) \
    $(call autoclean,ntp-dirclean)

$(eval $(call create-common-defs,ntp,NTP,-))

NTP_INSTALL_TARGET = SUBDIRS=src install-exec install-data

$(NTP_DIR)/.hostinst: $(NTP_DIR)/.built
	$(Q)touch $@

ntp-rt:
	$(Q){ rm -rf $(NTP_INSTDIR) && \
	    mkdir -p $(NTP_INSTDIR)/usr/sbin && \
	    mkdir -p $(NTP_INSTDIR)/usr/bin && \
	    mkdir -p $(NTP_INSTDIR)/etc && \
	    $(CP) $(SOURCES_DIR)/$(NTP_PDIR)/ntp.conf $(NTP_INSTDIR)/etc && \
	    $(CP) $(SOURCES_DIR)/$(NTP_PDIR)/ntp $(NTP_INSTDIR)/usr/bin && \
	    chmod +x $(NTP_INSTDIR)/usr/bin/ntp && \
	    $(CP) $(NTP_BDIR)/ntpq/ntpq $(NTP_INSTDIR)/usr/sbin && \
	    $(CP) $(NTP_BDIR)/ntpd/ntpd $(NTP_INSTDIR)/usr/sbin && \
	    $(CP) $(NTP_BDIR)/ntpdate/ntpdate $(NTP_INSTDIR)/usr/sbin \
	    $(call do-log,$(NTP_BDIR)/posthostinst.out); }
	$(Q)(cd $(NTP_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all usr/sbin/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) ntp-$(NTP_VERS).tgz \
		$(call do-log,$(NTP_BDIR)/makepkg.out) && \
	    mv ntp-$(NTP_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(NTP_INSTDIR)
