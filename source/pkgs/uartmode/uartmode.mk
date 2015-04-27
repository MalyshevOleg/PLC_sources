# Package: UARTMODE
UARTMODE_SDIR   = $(SOURCES_DIR)/pkgs/uartmode
UARTMODE_ITEMS  = $(UARTMODE_SDIR)/uartmode.c
UARTMODE_DIR    = $(PKGBUILD_DIR)/uartmode
UARTMODE_BDIR   = $(PKGBUILD_DIR)/uartmode/build
UARTMODE_INSTDIR= $(PKGINST_DIR)/uartmode

UARTMODE_RELIES = $(call patch-dep, $(UARTMODE_ITEMS))
UARTMODE_RELIES += $(call mk-dep,$(UARTMODE_SDIR)/uartmode.mk)

PHONY += uartmode uartmode-dirclean uartmode-clean

uartmode: toolchain $(UARTMODE_DIR)/.posthostinst

$(eval $(call create-install-targs,uartmode,UARTMODE))

$(UARTMODE_DIR)/.built: $(UARTMODE_RELIES) $(TOOLCHAIN_DIR)/.toolchain
	$(call print-info,[BUILD] UARTMODE target utility)
	$(Q)mkdir -p $(UARTMODE_BDIR) && cd $(UARTMODE_BDIR) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-gcc -O2 -o uartmode $(UARTMODE_ITEMS) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-strip -s uartmode
	$(Q)touch $@

$(UARTMODE_DIR)/.hostinst: $(UARTMODE_DIR)/.built
	$(Q)touch $@

$(UARTMODE_DIR)/.posthostinst: $(UARTMODE_DIR)/.hostinst
	$(Q){ rm -rf $(UARTMODE_INSTDIR) && \
	mkdir -p $(UARTMODE_INSTDIR)/sbin && \
	    $(CP) $(UARTMODE_BDIR)/uartmode $(UARTMODE_INSTDIR)/sbin/; }
	$(Q)(cd $(UARTMODE_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) uartmode.tgz \
		$(call do-log,$(UARTMODE_BDIR)/makepkg.out) && \
	    mv uartmode.tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(UARTMODE_INSTDIR)
	$(Q)$(call autoclean,uartmode-clean)
	$(Q)touch $@

uartmode-dirclean:
	$(Q)-rm -rf $(UARTMODE_BDIR)

uartmode-clean:
	$(Q)-rm -rf $(UARTMODE_DIR)
