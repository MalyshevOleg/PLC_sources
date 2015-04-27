# Package: FBSET
FBSET_VERS = 2.1
FBSET_EXT  = tar.gz
FBSET_SITE = http://users.telenet.be/geertu/Linux/fbdev
FBSET_PDIR = pkgs/fbset

FBSET_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
FBSET_MAKE_TARGS = CC=$(TARGET)-gcc

FBSET_RUNTIME_INSTALL = y
FBSET_DEPS = TOOLCHAIN

FBSET_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) fbset-rt) \
    $(call autoclean,fbset-dirclean)

$(eval $(call create-common-defs,fbset,FBSET,-))

$(FBSET_DIR)/.configured: $(FBSET_STEPS_DIR)/.patched
	$(call print-info,[CONFG] FBSET $(FBSET_VERS))
	$(Q)mkdir -p $(FBSET_BDIR) && cd $(FBSET_BDIR) && \
	    lndir $(FBSET_SDIR) > /dev/null
	$(Q)touch $@

$(FBSET_DIR)/.hostinst: $(FBSET_DIR)/.built
	$(Q)touch $@

fbset-rt:
	$(Q){ rm -rf $(FBSET_INSTDIR) && \
	    mkdir -p $(FBSET_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(FBSET_BDIR) DESTDIR=$(FBSET_INSTDIR) \
	    install \
	    $(call do-log,$(FBSET_BDIR)/posthostinst.out); }
	$(Q){ cd $(FBSET_INSTDIR); rm -rf usr; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) fbset-$(FBSET_VERS).tgz \
		$(call do-log,$(FBSET_BDIR)/makepkg.out) && \
	    mv fbset-$(FBSET_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;}
	$(Q)rm -rf $(FBSET_INSTDIR)
