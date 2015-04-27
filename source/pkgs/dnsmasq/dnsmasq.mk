DNSMASQ_VERS = 2.72
DNSMASQ_EXT  = tar.gz
DNSMASQ_SITE = http://www.thekelleys.org.uk/dnsmasq/
DNSMASQ_PDIR = pkgs/dnsmasq

DNSMASQ_MAKE_VARS =      PATH=$(TARGET_DIR)/bin:$$PATH \
                                CC=$(TARGET)-gcc 

DNSMASQ_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

DNSMASQ_RUNTIME_INSTALL = y
DNSMASQ_DEPS = TOOLCHAIN

$(eval $(call create-common-defs,dnsmasq,DNSMASQ,-))

DNSMASQ_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) dnsmasq-rt) \
                              $(call autoclean,dnsmasq-dirclean)

$(DNSMASQ_DIR)/.configured: $(DNSMASQ_STEPS_DIR)/.patched
	$(call print-info,[CONFG] DNSMASQ $(DNSMASQ_VERS))
	$(Q)mkdir -p $(DNSMASQ_BDIR) && \
		cd $(DNSMASQ_BDIR) && \
		lndir $(DNSMASQ_SDIR) >/dev/null 
	$(Q)touch $@

$(DNSMASQ_DIR)/.built: $(DNSMASQ_DIR)/.configured
	$(call print-info,[BUILD] DNSMASQ $(DNSMASQ_VERS))
	$(Q)$(MAKE) -C $(DNSMASQ_BDIR) $(DNSMASQ_MAKE_VARS) PREFIX=/usr $(call do-log,$(DNSMASQ_BDIR)/make.out)
	$(Q)touch $@

$(DNSMASQ_DIR)/.hostinst: $(DNSMASQ_DIR)/.built
	$(Q)touch $@

dnsmasq-rt:
	$(Q){ rm -rf $(DNSMASQ_INSTDIR) && \
	       mkdir -p $(DNSMASQ_INSTDIR) && \
	       CC=$(TARGET)-gcc $(MAKE) -C $(DNSMASQ_BDIR) PREFIX=/usr DESTDIR=$(DNSMASQ_INSTDIR) install \
	       $(call do-log,$(DNSMASQ_BDIR)/posthostinst.out); }
	$(Q){ cd $(DNSMASQ_INSTDIR) && rm -rf usr/share && \
		$(TARGET)-strip --strip-all usr/sbin/* && \
		$(MAKEPKG) dnsmasq-$(DNSMASQ_VERS).tgz $(call do-log,$(DNSMASQ_BDIR)/makepkg.out) && \
		mv dnsmasq-$(DNSMASQ_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/; }
	$(Q)rm -rf $(DNSMASQ_INSTDIR)

#		mkdir etc && $(CP) $(SOURCES_DIR)/$(DNSMASQ_PDIR)/files/dnsmasq.conf etc/dnsmasq.conf && \
