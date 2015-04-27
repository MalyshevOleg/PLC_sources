# Package: LINUX
LINUX_VERS_BASE?=3.0
LINUX_VERS?=3.0
LINUX_VERS_URL?=v3.0
ifeq "$(MACH)" "at91"
LINUX_DEFCONF:=owen_plc240_defconfig
else ifeq "$(MACH)" "s3c"
LINUX_DEFCONF:=spk107_defconfig
else ifeq "$(MACH_EXTRA)" "am33"
LINUX_DEFCONF:=som02_defconfig
else
LINUX_DEFCONF:=var-som-am35net_defconfig
endif
LINUX_EXT  = tar.bz2
LINUX_SITE = http://www.kernel.org/pub/linux/kernel/$(LINUX_VERS_URL)
LINUX_PDIR = toolchain/linux

$(eval $(call create-common-vars,linux,LINUX,-))

LINUX_BDIR  = $(LINUX_DIR)/build-$(BUILDCONF)
LINUX_OPT   = "O=$(LINUX_BDIR)"

$(LINUX_SOURCE_TARGET):
	$(call print-info,[FETCH] linux kernel $(LINUX_VERS))
	$(Q)mkdir -p $(LINUX_DL_DIR)
	$(call fetch-remote,$(LINUX_DL_DIR),$(LINUX_SOURCE_URL))

$(LINUX_STEPS_DIR)/.unpacked: $(LINUX_SOURCE_TARGET) \
    $(LINUX_PATCH_DIR)/*.bz2 $(LINUX_PATCH_DIR)/*.patch
	$(call print-info,[UNPAC] linux kernel $(LINUX_VERS))
	$(Q)mkdir -p $(PKGSOURCE_DIR) $(LINUX_STEPS_DIR) && \
	    rm -rf $(LINUX_SDIR) && \
	$(INFLATE$(suffix $(LINUX_EXT))) $(LINUX_SOURCE_TARGET) | \
	    $(TAR) -C $(PKGSOURCE_DIR) $(UNTAR_OPTS) -
	$(Q)touch $@

$(LINUX_STEPS_DIR)/.patched: $(LINUX_STEPS_DIR)/.unpacked
	$(call print-info,[PATCH] linux kernel $(LINUX_VERS))
	$(Q)mkdir -p $(LINUX_BDIR) && scripts/patch-kernel.sh \
	    $(LINUX_SDIR) $(LINUX_PATCH_DIR)/ \*.{bz2,patch} \
	    $(call do-log,$(LINUX_BDIR)/patch.out)
	$(Q)touch $@

linux-fetch: $(LINUX_SOURCE_TARGET)
linux-unpack: linux-fetch $(LINUX_STEPS_DIR)/.unpacked
linux-patch: linux-unpack $(LINUX_STEPS_DIR)/.patched

$(TOOLCHAIN_DIR)/.headers: $(LINUX_SOURCE_TARGET)
# unpack kernel sources
	$(call print-info,[UNPAC] linux kernel $(LINUX_VERS))
	$(Q)mkdir -p $(PKGSOURCE_DIR) && rm -rf $(LINUX_SDIR) && \
	$(INFLATE$(suffix $(LINUX_EXT))) $(LINUX_SOURCE_TARGET) | \
	    $(TAR) -C $(PKGSOURCE_DIR) $(UNTAR_OPTS) -
	$(call print-info,[PATCH] linux kernel $(LINUX_VERS))
	$(Q)mkdir -p $(LINUX_BDIR) && scripts/patch-kernel.sh \
	    $(LINUX_SDIR) $(LINUX_PATCH_DIR)/ \*.{bz2,patch} \
	    $(call do-log,$(LINUX_BDIR)/patch.out)
# prepare and install kernel headers
	$(call print-info,[INSTL] linux headers $(LINUX_VERS))
	$(Q)mkdir -p $(TARGET_DIR) && cd $(TARGET_DIR) && \
	     $(SUDO) rm -rf $(TARGET)/include include && \
	     $(SUDO) ln -s $(TARGET)/include include
	$(Q)$(SUDO) $(MAKE) CC=$(HOST_CC) ARCH=$(TARGET_CPU) \
	    -C $(LINUX_SDIR) $(LINUX_OPT) \
	    INSTALL_HDR_PATH=$(TARGET_DIR)/$(TARGET) headers_install \
	    $(call do-log,$(LINUX_BDIR)/hdrsinstall.out)
# clean up include dir from trash files
	$(Q)cd $(TARGET_DIR)/$(TARGET)/include && \
	    find . -name "\.*install*" | xargs $(SUDO) rm -f
# fix latest kernel header for busybox build
	$(Q)$(SUDO) $(SED) -i -e '5i\#include <asm/byteorder.h>' \
	    $(TARGET_DIR)/$(TARGET)/include/linux/if_tunnel.h
	$(Q)mkdir -p $(TOOLCHAIN_DIR) && touch $@

linux-headers: $(TOOLCHAIN_DIR)/.headers

$(LINUX_DIR)/.configured: $(LINUX_STEPS_DIR)/.patched
	$(call print-info,[CONFG] linux kernel with $(LINUX_DEFCONF))
# update build revision number
	$(Q){ if [ "$(MACH)" = "at91" ]; then $(SUDO) $(SED) -i -e "/#define OWEN_/s,_RELEASE\(.*\),_RELEASE\t$(BUILD_VERSION)," $(LINUX_SDIR)/arch/arm/mach-at91/owen-release.h; fi; }
	$(Q)$(SUDO) rm -rf $(LINUX_BDIR) && mkdir -p $(LINUX_BDIR)
	$(Q)$(MAKE) -C $(LINUX_SDIR) ARCH=$(TARGET_CPU) \
	    $(LINUX_OPT) $(LINUX_DEFCONF) \
	    $(call do-log,$(LINUX_BDIR)/configure.out)
	$(Q)touch $@

linux-conf: $(LINUX_DIR)/.configured

$(LINUX_DIR)/.compiled: $(LINUX_DIR)/.configured
	$(call print-info,[BUILD] linux kernel $(LINUX_VERS))
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(LINUX_SDIR) ARCH=$(TARGET_CPU) \
	    $(LINUX_OPT) CROSS_COMPILE=$(TARGET)- \
	    uImage modules INSTALL_MOD_PATH=$(RUNTIME_DIR) \
	    $(call do-log,$(LINUX_BDIR)/make.out)
	$(Q)touch $@

linux-build: zlib u-boot $(LINUX_DIR)/.compiled

$(LINUX_DIR)/.rtinstall: $(LINUX_DIR)/.compiled
	$(call print-info,[INSTL] linux kernel $(LINUX_VERS))
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	     $(MAKE) -C $(LINUX_SDIR) $(LINUX_OPT) ARCH=$(TARGET_CPU) \
	     modules_install INSTALL_MOD_PATH=$(RUNTIME_DIR) \
	    $(call do-log,$(LINUX_BDIR)/hostinstall.out)
	$(Q)touch $@

linux-inst: $(LINUX_DIR)/.rtinstall

linux-dirclean:
	$(call print-info,[DIRCL] linux kernel $(LINUX_VERS))
	$(Q)$(SUDO) rm -rf $(LINUX_SDIR) $(LINUX_BDIR)

linux-clean:
	$(call print-info,[CLEAN] linux kernel $(LINUX_VERS))
	$(Q)rm -rf $(LINUX_SDIR) $(LINUX_DIR) $(LINUX_STEPS_DIR)
