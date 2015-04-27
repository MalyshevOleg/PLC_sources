# Package: USBRESET
USBRESET_SDIR   = $(SOURCES_DIR)/pkgs/usbreset
USBRESET_ITEMS  = $(USBRESET_SDIR)/usbreset.c
USBRESET_DIR    = $(PKGBUILD_DIR)/usbreset
USBRESET_BDIR   = $(PKGBUILD_DIR)/usbreset/build
USBRESET_INSTDIR= $(PKGINST_DIR)/usbreset

USBRESET_RELIES = $(call patch-dep, $(USBRESET_ITEMS))
USBRESET_RELIES += $(call mk-dep,$(USBRESET_SDIR)/usbreset.mk)

PHONY += usbreset usbreset-dirclean usbreset-clean

usbreset: toolchain $(USBRESET_DIR)/.posthostinst

$(eval $(call create-install-targs,usbreset,USBRESET))

$(USBRESET_DIR)/.built: $(USBRESET_RELIES) $(TOOLCHAIN_DIR)/.toolchain
	$(call print-info,[BUILD] USBRESET target utility)
	$(Q)mkdir -p $(USBRESET_BDIR) && cd $(USBRESET_BDIR) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-gcc -O2 -o usbreset $(USBRESET_ITEMS) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-strip -s usbreset
	$(Q)touch $@

$(USBRESET_DIR)/.hostinst: $(USBRESET_DIR)/.built
	$(Q)touch $@

$(USBRESET_DIR)/.posthostinst: $(USBRESET_DIR)/.hostinst
	$(Q){ rm -rf $(USBRESET_INSTDIR) && \
	mkdir -p $(USBRESET_INSTDIR)/usr/sbin && \
          $(CP) $(USBRESET_BDIR)/usbreset $(USBRESET_INSTDIR)/usr/sbin/ ; \
        }
	$(Q)(cd $(USBRESET_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) usbreset.tgz \
		$(call do-log,$(USBRESET_BDIR)/makepkg.out) && \
	    mv usbreset.tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(USBRESET_INSTDIR)
	$(Q)$(call autoclean,usbreset-clean)
	$(Q)touch $@

usbreset-dirclean:
	$(Q)-rm -rf $(USBRESET_BDIR)

usbreset-clean:
	$(Q)-rm -rf $(USBRESET_DIR)
