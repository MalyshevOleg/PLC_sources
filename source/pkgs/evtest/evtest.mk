# Package: EVTEST
EVTEST_SDIR   = $(SOURCES_DIR)/pkgs/evtest
EVTEST_ITEMS  = $(EVTEST_SDIR)/evtest.c
EVTEST_DIR    = $(PKGBUILD_DIR)/evtest
EVTEST_BDIR   = $(PKGBUILD_DIR)/evtest/build
EVTEST_INSTDIR= $(PKGINST_DIR)/evtest

EVTEST_RELIES = $(call patch-dep, $(EVTEST_ITEMS))
EVTEST_RELIES += $(call mk-dep,$(EVTEST_SDIR)/evtest.mk)

PHONY += evtest evtest-dirclean evtest-clean

evtest: toolchain $(EVTEST_DIR)/.posthostinst

$(eval $(call create-install-targs,evtest,EVTEST))

$(EVTEST_DIR)/.built: $(EVTEST_RELIES) $(TOOLCHAIN_DIR)/.toolchain
	$(call print-info,[BUILD] EVTEST target utility)
	$(Q)mkdir -p $(EVTEST_BDIR) && cd $(EVTEST_BDIR) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-gcc -O2 -o evtest $(EVTEST_ITEMS) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-strip -s evtest
	$(Q)touch $@

$(EVTEST_DIR)/.hostinst: $(EVTEST_DIR)/.built
	$(Q)touch $@

$(EVTEST_DIR)/.posthostinst: $(EVTEST_DIR)/.hostinst
	$(Q){ rm -rf $(EVTEST_INSTDIR) && \
	mkdir -p $(EVTEST_INSTDIR)/sbin && \
	    $(CP) $(EVTEST_BDIR)/evtest $(EVTEST_INSTDIR)/sbin/; }
	$(Q)(cd $(EVTEST_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) evtest.tgz \
		$(call do-log,$(EVTEST_BDIR)/makepkg.out) && \
	    mv evtest.tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(EVTEST_INSTDIR)
	$(Q)$(call autoclean,evtest-clean)
	$(Q)touch $@

evtest-dirclean:
	$(Q)-rm -rf $(EVTEST_BDIR)

evtest-clean:
	$(Q)-rm -rf $(EVTEST_DIR)
