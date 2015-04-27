# Package: IPROUTE2
IPROUTE2_VERS = 2.6.39
IPROUTE2_EXT  = tar.gz
IPROUTE2_SITE = http://sources.buildroot.net
IPROUTE2_PDIR = pkgs/iproute2

IPROUTE2_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc
IPROUTE2_CONFIG_OPTS = Config

IPROUTE2_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
IPROUTE2_MAKE_TARGS = SUBDIRS="lib ip" \
    SDIR=$(IPROUTE2_SDIR)/ AR=$(TARGET)-ar CC=$(TARGET)-gcc

IPROUTE2_RUNTIME_INSTALL = y
IPROUTE2_DEPS = IPTABLES

IPROUTE2_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) iproute2-rt) \
    $(call autoclean,iproute2-dirclean)

$(eval $(call create-common-defs,iproute2,IPROUTE2,-))

$(IPROUTE2_DIR)/.configured: $(IPROUTE2_STEPS_DIR)/.patched
	$(call print-info,[CONFG] IPROUTE2 $(IPROUTE2_VERS))
	$(Q)mkdir -p $(IPROUTE2_BDIR)/lib $(IPROUTE2_BDIR)/ip && \
	$(CP) $(IPROUTE2_SDIR)/Makefile $(IPROUTE2_BDIR)/ && \
	$(CP) $(IPROUTE2_SDIR)/configure $(IPROUTE2_BDIR)/ && \
	$(CP) $(IPROUTE2_SDIR)/lib/Makefile $(IPROUTE2_BDIR)/lib/ && \
	$(CP) $(IPROUTE2_SDIR)/ip/Makefile $(IPROUTE2_BDIR)/ip/ && \
	$(IPROUTE2_CONFIG_VARS) \
	    $(MAKE) -C $(IPROUTE2_BDIR) $(IPROUTE2_CONFIG_OPTS) \
	    $(call do-log,$(IPROUTE2_BDIR)/configure.out)
	$(Q)touch $@

# TODO: install headers and libs to host cross-build directory
#	$(Q)install -m 0644 $(IPROUTE2_SDIR)/include/libnetlink.h $(TARGET_DIR)/$(TARGET)/include
#	$(Q)install -m 0644 $(IPROUTE2_BDIR)/lib/libnetlink.a $(TARGET_DIR)/$(TARGET)/lib
$(IPROUTE2_DIR)/.hostinst: $(IPROUTE2_DIR)/.built
	$(Q)touch $@

iproute2-rt:
	$(Q){ rm -rf $(IPROUTE2_INSTDIR) && \
	mkdir -p $(IPROUTE2_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(IPROUTE2_BDIR)/ip TARGETS=ip \
	    DESTDIR=$(IPROUTE2_INSTDIR) SBINDIR=/sbin/ install \
	    $(call do-log,$(IPROUTE2_BDIR)/posthostinst.out); }
	$(Q){ cd $(IPROUTE2_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all sbin/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) iproute2-$(IPROUTE2_VERS).tgz \
		$(call do-log,$(IPROUTE2_BDIR)/makepkg.out) && \
	    mv iproute2-$(IPROUTE2_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;}
	$(Q)rm -rf $(IPROUTE2_INSTDIR)
