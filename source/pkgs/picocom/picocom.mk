# Package: PICOCOM
PICOCOM_VERS = 1.6
PICOCOM_EXT  = tar.gz
PICOCOM_SITE = http://picocom.googlecode.com/files
PICOCOM_PDIR = pkgs/picocom

PICOCOM_CONFIG_VARS = chmod +x $(PICOCOM_SDIR)/configure;

PICOCOM_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
PICOCOM_MAKE_TARGS = CC=$(TARGET)-gcc

PICOCOM_RUNTIME_INSTALL = y
PICOCOM_DEPS = TOOLCHAIN

PICOCOM_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) picocom-rt) \
    $(call autoclean,picocom-dirclean)

$(eval $(call create-common-defs,picocom,PICOCOM,-))

$(PICOCOM_DIR)/.hostinst: $(PICOCOM_DIR)/.built
	$(Q)touch $@

picocom-rt:
	$(Q)( rm -rf $(PICOCOM_INSTDIR) && \
	mkdir -p $(PICOCOM_INSTDIR)/usr/bin && \
	    cp $(PICOCOM_BDIR)/picocom $(PICOCOM_INSTDIR)/usr/bin/ && \
	    cd $(PICOCOM_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all usr/bin/picocom && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) picocom-$(PICOCOM_VERS).tgz \
	        $(call do-log,$(PICOCOM_BDIR)/makepkg.out) && \
	    mv picocom-$(PICOCOM_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(PICOCOM_INSTDIR)
