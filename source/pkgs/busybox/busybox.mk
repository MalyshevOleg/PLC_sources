# Package: BUSYBOX
BUSYBOX_VERS = 1.19.3
BUSYBOX_EXT  = tar.bz2
#BUSYBOX_SITE = http://www.busybox.net/downloads
BUSYBOX_SITE = http://pkgs.fedoraproject.org/repo/pkgs/busybox/busybox-1.19.3.tar.bz2/c3938e1ac59602387009bbf1dd1af7f6
BUSYBOX_PDIR = pkgs/busybox

BUSYBOX_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
BUSYBOX_MAKE_TARGS = V=$(VERBOSE) ARCH=arm CROSS_COMPILE=$(TARGET)-
BUSYBOX_RUNTIME_INSTALL = y
BUSYBOX_DEPS = TOOLCHAIN

BUSYBOX_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) busybox-rt) \
    $(call autoclean,busybox-dirclean)

$(eval $(call create-common-defs,busybox,BUSYBOX,-))

$(BUSYBOX_DIR)/.configured: $(BUSYBOX_STEPS_DIR)/.patched
	$(call print-info,[CONFG] BUSYBOX $(BUSYBOX_VERS))
	$(Q)mkdir -p $(BUSYBOX_BDIR) && \
	$(CP) $(BUSYBOX_PATCH_DIR)/default-Config.conf \
	    $(BUSYBOX_BDIR)/.config && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(BUSYBOX_SDIR) O=$(BUSYBOX_BDIR) oldconfig \
	    $(call do-log,$(BUSYBOX_BDIR)/configure.out)
	$(Q)touch $@

$(BUSYBOX_DIR)/.hostinst: $(BUSYBOX_DIR)/.built
	$(Q)touch $@

busybox-rt:
	$(Q){ rm -rf $(BUSYBOX_INSTDIR) && \
	mkdir -p $(BUSYBOX_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(BUSYBOX_BDIR) CONFIG_PREFIX=$(BUSYBOX_INSTDIR) \
	    ARCH=arm CROSS_COMPILE=$(TARGET)- install \
	    $(call do-log,$(BUSYBOX_BDIR)/posthostinst.out); }
	$(Q){ cd $(BUSYBOX_INSTDIR) && mkdir -p usr/share/udhcpc && \
	    $(CP) $(BUSYBOX_SDIR)/examples/udhcp/simple.script \
		 usr/share/udhcpc/default.script && \
	    chmod +x usr/share/udhcpc/default.script && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) busybox-$(BUSYBOX_VERS).tgz \
	    $(call do-log,$(BUSYBOX_BDIR)/makepkg.out) && \
	    mv busybox-$(BUSYBOX_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;}
	$(Q)rm -rf $(BUSYBOX_INSTDIR)
