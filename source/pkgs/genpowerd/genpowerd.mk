# Package: GENPOWERD
GENPOWERD_VERS = 1.0.5
GENPOWERD_EXT  = tar.bz2
GENPOWERD_PDIR = pkgs/genpowerd
GENPOWERD_SITE = file://$(SOURCES_DIR)/$(GENPOWERD_PDIR)

GENPOWERD_MAKE_VARS = $(Q)PATH=$(TARGET_DIR)/bin:$$PATH
GENPOWERD_MAKE_TARGS = SDIR=$(GENPOWERD_SDIR)/ \
    CC=$(TARGET)-gcc STRIP=$(TARGET)-strip

GENPOWERD_RUNTIME_INSTALL = y
GENPOWERD_DEPS = TOOLCHAIN

GENPOWERD_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) genpowerd-rt) \
    $(call autoclean,genpowerd-dirclean)

$(eval $(call create-common-defs,genpowerd,GENPOWERD,-))

$(GENPOWERD_DIR)/.configured: $(GENPOWERD_STEPS_DIR)/.patched
	$(call print-info,[CONFG] GENPOWERD $(GENPOWERD_VERS))
	$(Q)mkdir -p $(GENPOWERD_BDIR) && \
	$(CP) $(GENPOWERD_SDIR)/Makefile $(GENPOWERD_BDIR)
	$(Q)touch $@

$(GENPOWERD_DIR)/.hostinst: $(GENPOWERD_DIR)/.built
	$(Q)touch $@

genpowerd-rt:
	$(Q){ rm -rf $(GENPOWERD_INSTDIR) && \
	mkdir -p $(GENPOWERD_INSTDIR)/sbin && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(GENPOWERD_BDIR) SDIR=$(GENPOWERD_SDIR)/ \
	    BINDIR=$(GENPOWERD_INSTDIR)/sbin/ STRIP=$(TARGET)-strip \
	    install \
	    $(call do-log,$(GENPOWERD_BDIR)/posthostinst.out); }
	$(Q)(cd $(GENPOWERD_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) genpowerd-$(GENPOWERD_VERS).tgz \
		$(call do-log,$(GENPOWERD_BDIR)/makepkg.out) && \
	    mv genpowerd-$(GENPOWERD_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(GENPOWERD_INSTDIR)
