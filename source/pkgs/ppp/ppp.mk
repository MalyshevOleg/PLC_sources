# Package: PPP
PPP_VERS = 2.4.5
PPP_EXT  = tar.gz
PPP_SITE = http://ftp.samba.org/pub/ppp
PPP_PDIR = pkgs/ppp

PPP_CONFIG_VARS = cd $(PPP_BDIR) && lndir $(PPP_SDIR) > /dev/null && \
    PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os" \
    CC=$(TARGET)-gcc SRCDIR=$(PPP_SDIR)
PPP_CONFIG_OPTS = \
    --prefix=/usr \
    --crosspath=$(TARGET_DIR)/$(TARGET)

PPP_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CC=$(TARGET)-gcc

PPP_RUNTIME_INSTALL = y
PPP_DEPS = TOOLCHAIN

PPP_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) ppp-rt) \
    $(call autoclean,ppp-dirclean)

$(eval $(call create-common-defs,ppp,PPP,-))

$(PPP_DIR)/.hostinst: $(PPP_DIR)/.built
	$(Q)touch $@

ppp-rt:
	$(Q){ rm -rf $(PPP_INSTDIR) && \
	mkdir -p $(PPP_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH INSTROOT=$(PPP_INSTDIR) \
	    STRIPPROG=$(TARGET)-strip \
	    $(MAKE) -C $(PPP_BDIR) STRIP=$(TARGET)-strip \
	    install-progs install-etcppp \
	    $(call do-log,$(PPP_BDIR)/posthostinst.out); }
	$(Q)(cd $(PPP_INSTDIR); \
	    rm -rf usr/share; \
	    $(TARGET)-strip usr/sbin/* usr/lib/pppd/$(PPP_VERS)/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) ppp-$(PPP_VERS).tgz \
		$(call do-log,$(PPP_BDIR)/makepkg.out) && \
	    mv ppp-$(PPP_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(PPP_INSTDIR)
