# Package: REPGEN
REPGEN_VERS = 1.10
REPGEN_EXT  = tar.gz
REPGEN_PDIR = pkgs/repgen
REPGEN_SITE = file://$(SOURCES_DIR)/$(REPGEN_PDIR)

REPGEN_MAKE_VARS = $(Q)PATH=$(TARGET_DIR)/bin:$$PATH
REPGEN_MAKE_TARGS = SRCDIR=$(REPGEN_SDIR)/ CC=$(TARGET)-gcc \
    LD=$(TARGET)-ld STRIP=$(TARGET)-strip strip

REPGEN_RUNTIME_INSTALL = y
REPGEN_DEPS = LIBMODBUS

REPGEN_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) repgen-rt) \
    $(call autoclean,repgen-dirclean)

$(eval $(call create-common-defs,repgen,REPGEN,-))

$(REPGEN_DIR)/.configured: $(REPGEN_STEPS_DIR)/.patched
	$(call print-info,[CONFG] REPGEN $(REPGEN_VERS))
	$(Q)mkdir -p $(REPGEN_BDIR) && \
	$(CP) $(REPGEN_SDIR)/Makefile $(REPGEN_BDIR)/
	$(Q)touch $@

$(REPGEN_DIR)/.hostinst: $(REPGEN_DIR)/.built
	$(Q)touch $@

repgen-rt:
	$(Q){ rm -rf $(REPGEN_INSTDIR) && \
	mkdir -p $(REPGEN_INSTDIR) && \
	    cd $(REPGEN_INSTDIR) && \
	    install -d -m 755 $(REPGEN_INSTDIR)/root && \
	    install -m 755 $(REPGEN_BDIR)/repgen \
		$(REPGEN_INSTDIR)/root/repgen && \
	    install -m 755 $(REPGEN_SDIR)/check_last_day.sh \
		$(REPGEN_INSTDIR)/root/check_last_day.sh; }
	$(Q)(cd $(REPGEN_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) repgen-$(REPGEN_VERS).tgz \
		$(call do-log,$(REPGEN_BDIR)/makepkg.out) && \
	    mv repgen-$(REPGEN_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(REPGEN_INSTDIR)
