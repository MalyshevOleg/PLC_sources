# Package: TS_PRESS
TS_PRESS_SDIR   = $(SOURCES_DIR)/pkgs/ts_press
TS_PRESS_ITEMS  = $(TS_PRESS_SDIR)/ts_press.c
TS_PRESS_DIR    = $(PKGBUILD_DIR)/ts_press
TS_PRESS_BDIR   = $(PKGBUILD_DIR)/ts_press/build
TS_PRESS_INSTDIR= $(PKGINST_DIR)/ts_press

TS_PRESS_DEPS = TSLIB 

TS_PRESS_RELIES = $(call patch-dep, $(TS_PRESS_ITEMS))
TS_PRESS_RELIES += $(call mk-dep,$(TS_PRESS_SDIR)/ts_press.mk)

PHONY += ts_press ts_press-dirclean ts_press-clean

ts_press: toolchain $(TS_PRESS_DIR)/.posthostinst

$(eval $(call create-install-targs,ts_press,TS_PRESS))

$(TS_PRESS_DIR)/.built: $(TS_PRESS_RELIES) $(TOOLCHAIN_DIR)/.toolchain $(TSLIB_DIR)/.hostinst
	$(call print-info,[BUILD] TS_PRESS target utility)
	$(Q)mkdir -p $(TS_PRESS_BDIR) && cd $(TS_PRESS_BDIR) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-gcc -O2 -o ts_press $(TS_PRESS_ITEMS) -lts -ldl && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-strip -s ts_press
	$(Q)touch $@

$(TS_PRESS_DIR)/.hostinst: $(TS_PRESS_DIR)/.built
	$(Q)touch $@

$(TS_PRESS_DIR)/.posthostinst: $(TS_PRESS_DIR)/.hostinst
	$(Q){ rm -rf $(TS_PRESS_INSTDIR) && \
	mkdir -p $(TS_PRESS_INSTDIR)/usr/bin && \
	    $(CP) $(TS_PRESS_BDIR)/ts_press $(TS_PRESS_INSTDIR)/usr/bin/; }
	$(Q)(cd $(TS_PRESS_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) ts_press.tgz \
		$(call do-log,$(TS_PRESS_BDIR)/makepkg.out) && \
	    mv ts_press.tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(TS_PRESS_INSTDIR)
	$(Q)$(call autoclean,ts_press-clean)
	$(Q)touch $@

ts_press-dirclean:
	$(Q)-rm -rf $(TS_PRESS_BDIR)

ts_press-clean:
	$(Q)-rm -rf $(TS_PRESS_DIR)
