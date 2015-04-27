# Package: IPERF
IPERF_VERS = 2.0.5
IPERF_EXT  = tar.gz
IPERF_SITE = http://downloads.sourceforge.net/project/iperf
IPERF_PDIR = pkgs/iperf

IPERF_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-Os" CC=$(TARGET)-gcc \
    ac_cv_func_malloc_0_nonnull=yes \
    ac_cv_type_bool=yes \
    ac_cv_sizeof_bool=1
IPERF_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr \
    --disable-dependency-tracking \
    --disable-web100

IPERF_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

IPERF_RUNTIME_INSTALL = y
IPERF_DEPS = TOOLCHAIN

IPERF_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) iperf-rt) \
    $(call autoclean,iperf-dirclean)

$(eval $(call create-common-defs,iperf,IPERF,-))

$(IPERF_DIR)/.hostinst: $(IPERF_DIR)/.built
	$(Q)touch $@

iperf-rt:
	$(Q){ rm -rf $(IPERF_INSTDIR) && \
	    mkdir -p $(IPERF_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(IPERF_BDIR) DESTDIR=$(IPERF_INSTDIR) \
	    install \
	    $(call do-log,$(IPERF_BDIR)/posthostinst.out); }
	$(Q){ cd $(IPERF_INSTDIR); rm -rf usr/share/man; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all usr/bin/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) iperf-$(IPERF_VERS).tgz \
		$(call do-log,$(IPERF_BDIR)/makepkg.out) && \
	    mv iperf-$(IPERF_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;}
	$(Q)rm -rf $(IPERF_INSTDIR)
