# Package: MODULE_INIT_TOOLS
MIT_VERS = 3.11
MIT_EXT  = tar.bz2
MIT_SITE = http://www.kernel.org/pub/linux/utils/kernel/module-init-tools
MIT_PDIR = pkgs/module-init-tools

MIT_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-O2"
MIT_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(HOST_CPU) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR)

MIT_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

MIT_DEPS = TOOLCHAIN

MIT_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) mit-rt) \
    $(call autoclean,mit-dirclean)

$(eval $(call create-common-vars,mit,MIT,-))
MIT_SRC  = module-init-tools-$(MIT_VERS).$(MIT_EXT)
MIT_SDIR = $(PKGSOURCE_DIR)/module-init-tools-$(MIT_VERS)
MIT_DIR  = $(PKGBUILD_DIR)/module-init-tools-$(MIT_VERS)
MIT_DL_DIR = $(DOWNLOAD_DIR)/module-init-tools-$(MIT_VERS)
MIT_STEPS_DIR = $(PKGSTEPS_DIR)/module-init-tools-$(MIT_VERS)
$(eval $(call create-common-targs,mit,MIT))
$(eval $(call create-install-targs,mit,MIT))

$(MIT_DIR)/.hostinst: $(MIT_DIR)/.built
	$(Q)strip $(MIT_BDIR)/depmod
	$(Q)touch $@

mit-rt:
	$(Q){ rm -rf $(MIT_INSTDIR) && \
	mkdir -p $(MIT_INSTDIR)/bin && \
	    $(CP) $(MIT_BDIR)/depmod $(MIT_INSTDIR)/bin ;}
	$(Q)(cd $(MIT_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) mit-$(MIT_VERS).tgz \
		$(call do-log,$(MIT_BDIR)/makepkg.out) && \
	    mv mit-$(MIT_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(MIT_INSTDIR)
