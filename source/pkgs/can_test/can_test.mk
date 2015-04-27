# Package: CAN_TEST
CAN_TEST_VERS = 1.0
CAN_TEST_EXT  = tar.gz
CAN_TEST_PDIR = pkgs/can_test
CAN_TEST_SITE = file://$(SOURCES_DIR)/$(CAN_TEST_PDIR)

CAN_TEST_MAKE_VARS = $(Q)PATH=$(TARGET_DIR)/bin:$$PATH
CAN_TEST_MAKE_TARGS = SRCDIR=$(CAN_TEST_SDIR) CC=$(TARGET)-gcc \
    LD=$(TARGET)-ld STRIP=$(TARGET)-strip strip

CAN_TEST_RUNTIME_INSTALL = y
CAN_TEST_DEPS = TOOLCHAIN

CAN_TEST_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) can_test-rt) \
    $(call autoclean,can_test-dirclean)

$(eval $(call create-common-defs,can_test,CAN_TEST,-))

$(CAN_TEST_DIR)/.configured: $(CAN_TEST_STEPS_DIR)/.patched
	$(call print-info,[CONFG] CAN_TEST $(CAN_TEST_VERS))
	$(Q)mkdir -p $(CAN_TEST_BDIR) && \
	$(CP) $(CAN_TEST_SDIR)/Makefile $(CAN_TEST_BDIR)/
	$(Q)touch $@

$(CAN_TEST_DIR)/.hostinst: $(CAN_TEST_DIR)/.built
	$(Q)touch $@

can_test-rt:
	$(Q){ rm -rf $(CAN_TEST_INSTDIR) && \
	mkdir -p $(CAN_TEST_INSTDIR) && \
	    cd $(CAN_TEST_INSTDIR) && \
	    install -d -m 755 $(CAN_TEST_INSTDIR)/usr/bin && \
	    install -m 755 $(CAN_TEST_BDIR)/can_raw_test \
		$(CAN_TEST_INSTDIR)/usr/bin/can_raw_test ; }
	$(Q)(cd $(CAN_TEST_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) can_test-$(CAN_TEST_VERS).tgz \
		$(call do-log,$(CAN_TEST_BDIR)/makepkg.out) && \
	    mv can_test-$(CAN_TEST_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(CAN_TEST_INSTDIR)
