# Package: FBMODE
FBMODE_SDIR   = $(SOURCES_DIR)/pkgs/fbmode
FBMODE_ITEMS  = $(FBMODE_SDIR)/fbmode.c
FBMODE_DIR    = $(PKGBUILD_DIR)/fbmode
FBMODE_BDIR   = $(PKGBUILD_DIR)/fbmode/build
FBMODE_INSTDIR= $(PKGINST_DIR)/fbmode

FBMODE_RELIES = $(call patch-dep, $(FBMODE_ITEMS))
FBMODE_RELIES += $(call mk-dep,$(FBMODE_SDIR)/fbmode.mk)

PHONY += fbmode fbmode-dirclean fbmode-clean

fbmode: toolchain $(FBMODE_DIR)/.posthostinst

$(eval $(call create-install-targs,fbmode,FBMODE))

$(FBMODE_DIR)/.built: $(FBMODE_RELIES) $(TOOLCHAIN_DIR)/.toolchain
	$(call print-info,[BUILD] FBMODE target utility)
	$(Q)mkdir -p $(FBMODE_BDIR) && cd $(FBMODE_BDIR) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-gcc -o fbmode $(FBMODE_ITEMS) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-strip -s fbmode
	$(Q)touch $@

$(FBMODE_DIR)/.hostinst: $(FBMODE_DIR)/.built
	$(Q)touch $@

$(FBMODE_DIR)/.posthostinst: $(FBMODE_DIR)/.hostinst
	$(Q){ rm -rf $(FBMODE_INSTDIR) && \
	mkdir -p $(FBMODE_INSTDIR)/sbin && \
	    $(CP) $(FBMODE_BDIR)/fbmode $(FBMODE_INSTDIR)/sbin/; }
	$(Q)(cd $(FBMODE_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) fbmode.tgz \
		$(call do-log,$(FBMODE_BDIR)/makepkg.out) && \
	    mv fbmode.tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(FBMODE_INSTDIR)
	$(Q)$(call autoclean,fbmode-clean)
	$(Q)touch $@

fbmode-dirclean:
	$(Q)-rm -rf $(FBMODE_BDIR)

fbmode-clean:
	$(Q)-rm -rf $(FBMODE_DIR)
