# Package: GFXKM
GFXKM_VERS? = 4.08.00.01
GFXKM_VERS_BASE? = 4.08.00.01

ifeq "$(GFXKM_VERS)" "4.08.00.01"
ES_VER=3
FB_PATH=dc_omapfb3_linux
else 
ES_VER=8
FB_PATH=dc_ti335x_linux
endif

GFXKM_EXT  = tar.bz2
GFXKM_PDIR = pkgs/gfxkm
GFXKM_SITE = file://$(SOURCES_DIR)/$(GFXKM_PDIR)

GFXKM_MAKE_TARGS = \
    CSTOOL_DIR=$(TARGET_DIR) \
    CSTOOL_PREFIX=$(TARGET)- \
    KERNEL_INSTALL_DIR=$(LINUX_BDIR) \
    GRAPHICS_INSTALL_DIR=$(GFXKM_BDIR) \
    OMAPES=$(ES_VER).x \
    BUILD=release buildkernel

GFXKM_RUNTIME_INSTALL = y
GFXKM_DEPS = LINUX

GFXKM_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) gfxkm-rt) \
    $(call autoclean,gfxkm-dirclean)

$(eval $(call create-common-defs,gfxkm,GFXKM,-))

GFXKM_BDIR = $(GFXKM_DIR)/build-$(BUILDCONF)

$(GFXKM_DIR)/.configured: $(GFXKM_STEPS_DIR)/.patched $(LINUX_DIR)/.configured
	$(call print-info,[CONFG] GFXKM $(GFXKM_VERS))
	$(Q)mkdir -p $(GFXKM_BDIR)/GFX_Linux_KM/services4/include/omapfb/ && \
	    cd $(GFXKM_BDIR)/GFX_Linux_KM && \
	    lndir $(GFXKM_SDIR)/GFX_Linux_KM > /dev/null && \
	    cd $(GFXKM_BDIR) && $(CP) $(GFXKM_SDIR)/*ake* .
	$(Q)touch $@

$(GFXKM_DIR)/.hostinst: $(GFXKM_DIR)/.built
	$(Q)touch $@

gfxkm-rt:
	$(Q){ cd $(GFXKM_BDIR)/GFX_Linux_KM && \
	    $(CP) services4/3rdparty/bufferclass_ti/bufferclass_ti.*o \
		services4/3rdparty/$(FB_PATH)/omaplfb.*o ./ && \
	    $(SED) -i -e '/ko$$/s,services4/3rdparty/[^/]\+/,,' .tmp_versions/*.mod && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(LINUX_BDIR) ARCH=$(TARGET_CPU) M=$(GFXKM_BDIR)/GFX_Linux_KM \
	    modules_install INSTALL_MOD_PATH=$(RUNTIME_DIR) \
	    $(call do-log,$(GFXKM_BDIR)/posthostinst.out); }
