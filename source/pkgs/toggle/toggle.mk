# Package: TOGGLE
TOGGLE_SDIR   = $(SOURCES_DIR)/pkgs/toggle
TOGGLE_ITEMS  = $(TOGGLE_SDIR)/toggle.c
TOGGLE_DIR    = $(PKGBUILD_DIR)/toggle
TOGGLE_BDIR   = $(PKGBUILD_DIR)/toggle/build
TOGGLE_INSTDIR= $(PKGINST_DIR)/toggle

TOGGLE_RELIES = $(call patch-dep, $(TOGGLE_ITEMS))
TOGGLE_RELIES += $(call mk-dep,$(TOGGLE_SDIR)/toggle.mk)

PHONY += toggle toggle-dirclean toggle-clean

toggle: toolchain $(TOGGLE_DIR)/.posthostinst

$(eval $(call create-install-targs,toggle,TOGGLE))

$(TOGGLE_DIR)/.built: $(TOGGLE_RELIES) $(TOOLCHAIN_DIR)/.toolchain
	$(call print-info,[BUILD] TOGGLE target utility)
	$(Q)mkdir -p $(TOGGLE_BDIR) && cd $(TOGGLE_BDIR) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-gcc -O2 -o toggle $(TOGGLE_ITEMS) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-strip -s toggle
	$(Q)touch $@

$(TOGGLE_DIR)/.hostinst: $(TOGGLE_DIR)/.built
	$(Q)touch $@

$(TOGGLE_DIR)/.posthostinst: $(TOGGLE_DIR)/.hostinst
	$(Q){ rm -rf $(TOGGLE_INSTDIR) && \
	mkdir -p $(TOGGLE_INSTDIR)/sbin && \
	    $(CP) $(TOGGLE_BDIR)/toggle $(TOGGLE_INSTDIR)/sbin/; }
	$(Q)(cd $(TOGGLE_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) toggle.tgz \
		$(call do-log,$(TOGGLE_BDIR)/makepkg.out) && \
	    mv toggle.tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(TOGGLE_INSTDIR)
	$(Q)$(call autoclean,toggle-clean)
	$(Q)touch $@

toggle-dirclean:
	$(Q)-rm -rf $(TOGGLE_BDIR)

toggle-clean:
	$(Q)-rm -rf $(TOGGLE_DIR)
