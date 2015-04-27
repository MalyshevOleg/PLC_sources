# Package: GFX

GFX_VERS? = 4.08.00.01
GFX_VERS_BASE? = 4.08.00.01
GFX_EXT  = tar.bz2
GFX_PDIR = pkgs/gfx
GFX_SITE = file://$(SOURCES_DIR)/$(GFX_PDIR)

ifeq "$(GFX_VERS)" "4.08.00.01"
ES_VER=3
else 
ES_VER=8
endif


GFX_LIBS4CROSS = libEGL.so libGLESv2.so libIMGegl.so libpvr2d.so libsrv_um.so

GFX_RUNTIME_INSTALL = y
GFX_DEPS = TOOLCHAIN

GFX_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) gfx-rt) \
    $(call autoclean,gfx-dirclean)

$(eval $(call create-common-defs,gfx,GFX,-))

$(GFX_DIR)/.configured: $(GFX_STEPS_DIR)/.patched
	$(call print-info,[CONFG] GFX $(GFX_VERS))
	$(Q)mkdir -p $(GFX_BDIR) && cd $(GFX_BDIR) && \
	    $(CP) $(GFX_SDIR)/*ake* .
	$(Q)touch $@

$(GFX_DIR)/.built: $(GFX_DIR)/.configured
	$(call print-info,[BUILD] GFX $(GFX_VERS))
	$(Q)touch $@

$(GFX_DIR)/.hostinst: $(GFX_DIR)/.built
	$(call print-info,[INSTL] GFX $(GFX_VERS) to host)
	$(Q)$(SUDO) $(CP) -a $(GFX_SDIR)/include/OGLES2/* $(TARGET_DIR)/include && \
	    $(SUDO) $(CP) -a $(GFX_SDIR)/include/OGLES/* $(TARGET_DIR)/include && \
	    $(SUDO) $(CP) $(GFX_SDIR)/include/pvr2d/* $(TARGET_DIR)/include && \
	    $(SUDO) $(CP) $(GFX_SDIR)/include/wsegl/* $(TARGET_DIR)/include
	$(Q){ cd $(GFX_SDIR)/gfx_rel_es$(ES_VER).x && \
	    $(SUDO) $(CP) $(GFX_LIBS4CROSS) $(TARGET_DIR)/$(TARGET)/lib ;}
	$(Q)touch $@

gfx-rt:
	$(Q){ rm -rf $(GFX_INSTDIR) && \
	mkdir -p $(GFX_INSTDIR)/etc && \
	    cd $(GFX_SDIR)/gfx_rel_es$(ES_VER).x && \
	    ./install.sh -r $(GFX_INSTDIR) \
	    $(call do-log,$(GFX_BDIR)/posthostinst.out); }
	$(Q){ cd $(GFX_INSTDIR); rm -f etc/*.log; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) gfx-$(GFX_VERS).tgz \
		$(call do-log,$(GFX_BDIR)/makepkg.out) && \
	    mv gfx-$(GFX_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;}
	$(Q)rm -rf $(GFX_INSTDIR)
