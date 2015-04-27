COMGT_VERS = 0.32
COMGT_SITE = file://$(SOURCES_DIR)/$(COMGT_PDIR)
COMGT_EXT  = tar.gz
COMGT_PDIR = pkgs/comgt


COMGT_SCRIPTS = etc/gcom

COMGT_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
	CC=$(TARGET)-gcc EXE=$(COMGT_INSTDIR)/usr/bin \
	MAN=$(COMGT_INSTDIR)/man \
	SCRIPTPATH=$(COMGT_INSTDIR)/$(COMGT_SCRIPTS)

COMGT_PKGDIR = $(SOURCES_DIR)/$(COMGT_PDIR)

COMGT_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

COMGT_RUNTIME_INSTALL = y
COMGT_DEPS = TOOLCHAIN

COMGT_ITEMS = files/evdo.chat \
		files/gsm.chat \
		files/cardinfo.gcom \
		files/carrier.gcom \
		files/cnum.gcom \
		files/imsi.gcom \
		files/command.gcom \
		files/setmode.gcom \
		files/setpin.gcom \
		files/strength.gcom

COMGT_RELIES = $(call patch-dep,$(addprefix $(COMGT_PKGDIR)/,$(COMGT_ITEMS)))
COMGT_RELIES += $(call mk-dep,$(COMGT_PKGDIR)/comgt.mk)

$(eval $(call create-common-defs,comgt,COMGT,-))

COMGT_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) comgt-rt) \
		     $(call autoclean,comgt-dirclean)

$(COMGT_DIR)/.configured: $(COMGT_STEPS_DIR)/.patched
	$(call print-info,[CONFG] COMGT $(COMGT_VERS))
	$(Q)mkdir -p $(COMGT_BDIR) && cd $(COMGT_BDIR) && \
		lndir $(COMGT_SDIR) > /dev/null
	$(Q)touch $@
	

$(COMGT_DIR)/.built: $(COMGT_RELIES) $(COMGT_DIR)/.configured
	$(call print-info,[BUILD] COMGT $(COMGT_VERS))
	$(Q)$(MAKE) -C $(COMGT_BDIR) $(COMGT_MAKE_VARS) $(call do-log,$(COMGT_BDIR)/make.out)
	$(Q)touch $@

$(COMGT_DIR)/.hostinst: $(COMGT_DIR)/.built
	$(Q)touch $@

comgt-rt:
	$(Q){	rm -rf $(COMGT_INSTDIR) && \
		$(MAKE) -C $(COMGT_BDIR) $(COMGT_MAKE_VARS) install $(call do-log,$(COMGT_BDIR)/posthostinst.out) && \
		install -m 0644 $(COMGT_PKGDIR)/files/*.chat $(COMGT_INSTDIR)/$(COMGT_SCRIPTS) && \
		install -m 0644 $(COMGT_PKGDIR)/files/*.gcom $(COMGT_INSTDIR)/$(COMGT_SCRIPTS) && \
		mv $(COMGT_INSTDIR)/$(COMGT_SCRIPTS)/info $(COMGT_INSTDIR)/$(COMGT_SCRIPTS)/info.gcom && \
		mv $(COMGT_INSTDIR)/$(COMGT_SCRIPTS)/send-sms $(COMGT_INSTDIR)/$(COMGT_SCRIPTS)/send-sms.gcom && \
		mv $(COMGT_INSTDIR)/$(COMGT_SCRIPTS)/read-sms $(COMGT_INSTDIR)/$(COMGT_SCRIPTS)/read-sms.gcom && \
		mv $(COMGT_INSTDIR)/$(COMGT_SCRIPTS)/dump $(COMGT_INSTDIR)/$(COMGT_SCRIPTS)/dump.gcom && \
		mv $(COMGT_INSTDIR)/$(COMGT_SCRIPTS)/operator $(COMGT_INSTDIR)/$(COMGT_SCRIPTS)/operator.gcom && \
		mv $(COMGT_INSTDIR)/$(COMGT_SCRIPTS)/sigmon $(COMGT_INSTDIR)/$(COMGT_SCRIPTS)/sigmon.gcom; }
	$(Q)(   cd $(COMGT_INSTDIR); rm -rf man $(COMGT_SCRIPTS)/command $(COMGT_SCRIPTS)/README; \
                $(TARGET)-strip usr/bin/* 2>/dev/null; \
		cd $(COMGT_INSTDIR)/usr/bin; ln -s comgt gcom; \
		cd $(COMGT_INSTDIR); \
		$(MAKEPKG) comgt-$(COMGT_VERS).tgz \
		$(call do-log,$(COMGT_BDIR)/makepkg.out) && \
		mv comgt-$(COMGT_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ )
	$(Q)rm -rf $(COMGT_INSTDIR)
