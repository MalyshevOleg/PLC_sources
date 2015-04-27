# Package: NTPSYNCSWITCH
NTPSYNCSWITCH_SDIR   = $(SOURCES_DIR)/pkgs/ntpsyncswitch
NTPSYNCSWITCH_ITEMS  = $(NTPSYNCSWITCH_SDIR)/ntpsyncswitch.c
NTPSYNCSWITCH_DIR    = $(PKGBUILD_DIR)/ntpsyncswitch
NTPSYNCSWITCH_BDIR   = $(PKGBUILD_DIR)/ntpsyncswitch/build
NTPSYNCSWITCH_INSTDIR= $(PKGINST_DIR)/ntpsyncswitch

NTPSYNCSWITCH_RELIES = $(call patch-dep, $(NTPSYNCSWITCH_ITEMS))
NTPSYNCSWITCH_RELIES += $(call mk-dep,$(NTPSYNCSWITCH_SDIR)/ntpsyncswitch.mk)

PHONY += ntpsyncswitch ntpsyncswitch-dirclean ntpsyncswitch-clean

ntpsyncswitch: toolchain $(NTPSYNCSWITCH_DIR)/.posthostinst

$(eval $(call create-install-targs,ntpsyncswitch,NTPSYNCSWITCH))

$(NTPSYNCSWITCH_DIR)/.built: $(NTPSYNCSWITCH_RELIES) $(TOOLCHAIN_DIR)/.toolchain
	$(call print-info,[BUILD] NTPSYNCSWITCH target utility)
	$(Q)mkdir -p $(NTPSYNCSWITCH_BDIR) && cd $(NTPSYNCSWITCH_BDIR) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-gcc -o ntpsyncswitch $(NTPSYNCSWITCH_ITEMS) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-strip -s ntpsyncswitch
	$(Q)touch $@

$(NTPSYNCSWITCH_DIR)/.hostinst: $(NTPSYNCSWITCH_DIR)/.built
	$(Q)touch $@

$(NTPSYNCSWITCH_DIR)/.posthostinst: $(NTPSYNCSWITCH_DIR)/.hostinst
	$(Q){ rm -rf $(NTPSYNCSWITCH_INSTDIR) && \
	mkdir -p $(NTPSYNCSWITCH_INSTDIR)/sbin && \
	    $(CP) $(NTPSYNCSWITCH_BDIR)/ntpsyncswitch $(NTPSYNCSWITCH_INSTDIR)/sbin/ && \
	    chmod 4755 $(NTPSYNCSWITCH_INSTDIR)/sbin/ntpsyncswitch; }
	$(Q)(cd $(NTPSYNCSWITCH_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) ntpsyncswitch.tgz \
		$(call do-log,$(NTPSYNCSWITCH_BDIR)/makepkg.out) && \
	    mv ntpsyncswitch.tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(NTPSYNCSWITCH_INSTDIR)
	$(Q)$(call autoclean,ntpsyncswitch-clean)
	$(Q)touch $@

ntpsyncswitch-dirclean:
	$(Q)-rm -rf $(NTPSYNCSWITCH_BDIR)

ntpsyncswitch-clean:
	$(Q)-rm -rf $(NTPSYNCSWITCH_DIR)
