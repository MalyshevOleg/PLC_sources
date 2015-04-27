# Package: POWERFAIL
POWERFAIL_SDIR   = $(SOURCES_DIR)/pkgs/powerfail
POWERFAIL_ITEMS  = $(POWERFAIL_SDIR)/powerfail.c
POWERFAIL_DIR    = $(PKGBUILD_DIR)/powerfail
POWERFAIL_BDIR   = $(PKGBUILD_DIR)/powerfail/build
POWERFAIL_INSTDIR= $(PKGINST_DIR)/powerfail

POWERFAIL_RELIES = $(call patch-dep, $(POWERFAIL_ITEMS))
POWERFAIL_RELIES += $(call mk-dep,$(POWERFAIL_SDIR)/powerfail.mk)

PHONY += powerfail powerfail-dirclean powerfail-clean

powerfail: toolchain $(POWERFAIL_DIR)/.posthostinst

$(eval $(call create-install-targs,powerfail,POWERFAIL))

$(POWERFAIL_DIR)/.built: $(POWERFAIL_RELIES) $(TOOLCHAIN_DIR)/.toolchain
	$(call print-info,[BUILD] POWERFAIL target utility)
	$(Q)mkdir -p $(POWERFAIL_BDIR) && cd $(POWERFAIL_BDIR) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-gcc -O2 -o powerfail $(POWERFAIL_ITEMS) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-strip -s powerfail
	$(Q)touch $@

$(POWERFAIL_DIR)/.hostinst: $(POWERFAIL_DIR)/.built
	$(Q)touch $@

$(POWERFAIL_DIR)/.posthostinst: $(POWERFAIL_DIR)/.hostinst
	$(Q){ rm -rf $(POWERFAIL_INSTDIR) && \
	mkdir -p $(POWERFAIL_INSTDIR)/sbin && \
	    $(CP) $(POWERFAIL_BDIR)/powerfail $(POWERFAIL_INSTDIR)/sbin/; }
	$(Q)(cd $(POWERFAIL_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) powerfail.tgz \
		$(call do-log,$(POWERFAIL_BDIR)/makepkg.out) && \
	    mv powerfail.tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(POWERFAIL_INSTDIR)
	$(Q)$(call autoclean,powerfail-clean)
	$(Q)touch $@

powerfail-dirclean:
	$(Q)-rm -rf $(POWERFAIL_BDIR)

powerfail-clean:
	$(Q)-rm -rf $(POWERFAIL_DIR)
