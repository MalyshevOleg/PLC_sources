# Package: ALSA-UTILS
V4L-UTILS_VERS = 0.8.9
V4L-UTILS_EXT  = tar.bz2
V4L-UTILS_SITE = http://sources.buildroot.net
V4L-UTILS_PDIR = pkgs/v4l-utils

V4L-UTILS_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
V4L-UTILS_MAKE_TARS = V=$(VERBOSE) ARCH=arm INCLUDE=$(PKGSOURCE_DIR)/jpeg-8d CROSS_COMPILE=$(TARGET)-

V4L-UTILS_RUNTIME_INSTALL = y
V4L-UTILS_DEPS = TOOLCHAIN JPEG


V4L-UTILS_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) v4l-utils-rt) \
    $(call autoclean,v4l-utils-dirclean)

$(eval $(call create-common-defs,v4l-utils,V4L-UTILS,-))

$(V4L-UTILS_DIR)/.configured: $(V4L-UTILS_STEPS_DIR)/.patched
	$(call print-info,[CONFG] V4L-UTILS $(V4L-UTILS_VERS))
	$(Q)mkdir -p $(V4L-UTILS_BDIR) && cd $(V4L-UTILS_BDIR) && \
		lndir $(V4L-UTILS_SDIR) > /dev/null
	$(CP) $(V4L-UTILS_PATCH_DIR)/default.config \
	    $(V4L-UTILS_BDIR)/.config && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(V4L-UTILS_SDIR) O=$(V4L-UTILS_BDIR) PKGSOURCE_DIR=$(PKGSOURCE_DIR) CROSS_COMPILE=$(TARGET) \
	    $(call do-log,$(V4L-UTILS_BDIR)/configure.out)
	$(Q)touch $@

$(V4L-UTILS_DIR)/.hostinst: $(V4L-UTILS_DIR)/.built
	$(Q)touch $@

v4l-utils-rt:
	$(Q){ rm -rf $(V4L-UTILS_INSTDIR) && \
	mkdir -p $(V4L-UTILS_INSTDIR) && \
	    cd $(V4L-UTILS_INSTDIR) && \
	    install -d -m 755 $(V4L-UTILS_INSTDIR)/lib && \
 	    install -m 644 $(V4L-UTILS_BDIR)/lib/libv4l2/v4l2convert.so    $(V4L-UTILS_INSTDIR)/lib/v4l2convert.so  &&   \
	    install -m 644 $(V4L-UTILS_BDIR)/lib/libv4l2/v4l2convert.so.0    $(V4L-UTILS_INSTDIR)/lib/v4l2convert.so.0  &&   \
	    install -m 644 $(V4L-UTILS_BDIR)/lib/libv4l2/libv4l2.so    $(V4L-UTILS_INSTDIR)/lib/libv4l2.so  &&   \
	    install -m 644 $(V4L-UTILS_BDIR)/lib/libv4l2/libv4l2.so.0    $(V4L-UTILS_INSTDIR)/lib/libv4l2.so.0  &&   \
	    install -m 644 $(V4L-UTILS_BDIR)/lib/libv4l1/libv4l1.so    $(V4L-UTILS_INSTDIR)/lib/libv4l1.so  &&   \
	    install -m 644 $(V4L-UTILS_BDIR)/lib/libv4l1/libv4l1.so.0    $(V4L-UTILS_INSTDIR)/lib/libv4l1.so.0  &&   \
	    install -m 644 $(V4L-UTILS_BDIR)/lib/libv4l1/v4l1compat.so    $(V4L-UTILS_INSTDIR)/lib/v4l1compat.so  &&   \
	    install -m 644 $(V4L-UTILS_BDIR)/lib/libv4l1/v4l1compat.so.0  $(V4L-UTILS_INSTDIR)/lib/v4l1compat.so.0 ; }
	$(Q)(cd $(V4L-UTILS_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) v4l-utils-$(V4L-UTILS_VERS).tgz \
		$(call do-log,$(V4L-UTILS_BDIR)/makepkg.out) && \
	    mv v4l-utils-$(V4L-UTILS_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(V4L-UTILS_INSTDIR)

