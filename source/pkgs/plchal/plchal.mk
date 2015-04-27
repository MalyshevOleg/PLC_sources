# Package: PLCHAL
PLCHAL_VERS = 8.35
PLCHAL_EXT  = tar.bz2
PLCHAL_PDIR = pkgs/plchal
PLCHAL_SITE = file://$(SOURCES_DIR)/$(PLCHAL_PDIR)

PLCHAL_MAKE_VARS = $(Q)PATH=$(TARGET_DIR)/bin:$$PATH
PLCHAL_MAKE_TARGS = SDIR=$(PLCHAL_SDIR)/ KERNEL_INC=$(LINUX_SDIR) \
    CC=$(TARGET)-gcc LD=$(TARGET)-ld STRIP=$(TARGET)-strip

PLCHAL_RUNTIME_INSTALL = y
PLCHAL_DEPS = TOOLCHAIN

PLCHAL_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) plchal-rt) \
    $(call autoclean,plchal-dirclean)

$(eval $(call create-common-defs,plchal,PLCHAL,-))

PLCHAL_INSTALL = $(Q)PATH=$(TARGET_DIR)/bin:$$PATH
PLCHAL_INSTALL_TARGET = SDIR=$(PLCHAL_SDIR)/ KERNEL_INC=$(LINUX_SDIR) \
    CC=$(TARGET)-gcc CCOPTS=-O2 LDFLAGS="-L$(PLCHAL_BDIR) -lplc" \
    LD=$(TARGET)-ld STRIP=$(TARGET)-strip tools/enum tools/garland_stat

$(PLCHAL_DIR)/.configured: $(PLCHAL_STEPS_DIR)/.patched $(TOOLCHAIN_DIR)/.headers
	$(call print-info,[CONFG] PLCHAL $(PLCHAL_VERS))
	$(Q)mkdir -p $(PLCHAL_BDIR)/tools && \
	$(CP) $(PLCHAL_SDIR)/Makefile $(PLCHAL_BDIR)/ && \
	$(CP) $(PLCHAL_SDIR)/tools/Makefile $(PLCHAL_BDIR)/tools
	$(Q)touch $@

plchal-rt:
	$(Q){ rm -rf $(PLCHAL_INSTDIR) && \
	    mkdir -p $(PLCHAL_INSTDIR) && \
	    cd $(PLCHAL_INSTDIR) && \
	    install -d -m 755 $(PLCHAL_INSTDIR)/usr/bin $(PLCHAL_INSTDIR)/lib && \
	    install -m 644 $(PLCHAL_BDIR)/libplc.so \
		$(PLCHAL_INSTDIR)/lib/libplc.so && \
	    install -m 755 $(PLCHAL_BDIR)/tools/enum \
		$(PLCHAL_INSTDIR)/usr/bin/enum && \
	    install -m 755 $(PLCHAL_BDIR)/tools/garland_stat \
		$(PLCHAL_INSTDIR)/usr/bin/garland_stat && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip $(PLCHAL_INSTDIR)/usr/bin/* ; }
	$(Q)(cd $(PLCHAL_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) plchal-$(PLCHAL_VERS).tgz \
		$(call do-log,$(PLCHAL_BDIR)/makepkg.out) && \
	    mv plchal-$(PLCHAL_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(PLCHAL_INSTDIR)
