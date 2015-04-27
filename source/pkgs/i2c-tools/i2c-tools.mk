# Package: I2C_TOOLS
I2C_TOOLS_VERS = 3.1.0
I2C_TOOLS_EXT  = tar.bz2
I2C_TOOLS_SITE = http://dl.lm-sensors.org/i2c-tools/releases
I2C_TOOLS_PDIR = pkgs/i2c-tools

I2C_TOOLS_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
I2C_TOOLS_MAKE_TARGS = CC=$(TARGET)-gcc

I2C_TOOLS_RUNTIME_INSTALL = y
I2C_TOOLS_DEPS = TOOLCHAIN

I2C_TOOLS_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) i2c-tools-rt) \
    $(call autoclean,i2c-tools-dirclean)

$(eval $(call create-common-defs,i2c-tools,I2C_TOOLS,-))

$(I2C_TOOLS_DIR)/.configured: $(I2C_TOOLS_STEPS_DIR)/.patched
	$(call print-info,[CONFG] I2C_TOOLS $(I2C_TOOLS_VERS))
	$(Q)mkdir -p $(I2C_TOOLS_BDIR) && cd $(I2C_TOOLS_BDIR) && \
	    lndir $(I2C_TOOLS_SDIR) > /dev/null
	$(Q)touch $@

$(I2C_TOOLS_DIR)/.hostinst: $(I2C_TOOLS_DIR)/.built
	$(Q)touch $@

i2c-tools-rt:
	$(Q){ rm -rf $(I2C_TOOLS_INSTDIR) && \
	    mkdir -p $(I2C_TOOLS_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(I2C_TOOLS_BDIR) DESTDIR=$(I2C_TOOLS_INSTDIR) \
	    install \
	    $(call do-log,$(I2C_TOOLS_BDIR)/posthostinst.out); }
	$(Q){ cd $(I2C_TOOLS_INSTDIR); rm -rf usr/{share,include,bin}; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all usr/sbin/i2c{detect,dump,get,set}; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) i2c-tools-$(I2C_TOOLS_VERS).tgz \
		$(call do-log,$(I2C_TOOLS_BDIR)/makepkg.out) && \
	    mv i2c-tools-$(I2C_TOOLS_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;}
	$(Q)rm -rf $(I2C_TOOLS_INSTDIR)
