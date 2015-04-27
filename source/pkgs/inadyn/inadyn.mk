# Package: INADYN
INADYN_VERS = 02.20.06
INADYN_EXT  = tar.gz
INADYN_PDIR = pkgs/inadyn
INADYN_SITE = file://$(SOURCES_DIR)/$(INADYN_PDIR)

INADYN_CONFIG_VARS = \
    rm -f $(INADYN_SDIR)/config.status $(INADYN_SDIR)/src/config.h && \
    PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os" \
    ac_cv_func_realloc_0_nonnull=yes \
    ac_cv_func_malloc_0_nonnull=yes
INADYN_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --oldincludedir=$(TARGET_DIR)/$(TARGET)/include \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --prefix=/usr \
    --disable-sound

INADYN_MAKE_VARS = $(Q)PATH=$(TARGET_DIR)/bin:$$PATH
INADYN_MAKE_TARGS = libdir=$(TARGET_DIR)/$(TARGET)/lib

INADYN_RUNTIME_INSTALL = y
INADYN_DEPS = TOOLCHAIN

INADYN_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) inadyn-rt) \
    $(call autoclean,inadyn-dirclean)

$(eval $(call create-common-vars,inadyn,INADYN,-mt.v.))
INADYN_SRC=inadyn-mt.v.$(INADYN_VERS).$(INADYN_EXT)
INADYN_SDIR=$(PKGSOURCE_DIR)/inadyn-mt.v.$(INADYN_VERS)
INADYN_DL_DIR=$(DOWNLOAD_DIR)/inadyn-$(INADYN_VERS)
$(eval $(call create-common-targs,inadyn,INADYN))
$(eval $(call create-install-targs,inadyn,INADYN))

$(INADYN_DIR)/.hostinst: $(INADYN_DIR)/.built
	$(Q)touch $@

inadyn-rt:
	$(Q){ rm -rf $(INADYN_INSTDIR) && \
	mkdir -p $(INADYN_INSTDIR) && \
	    cd $(INADYN_INSTDIR) && \
	    install -d -m 755 $(INADYN_INSTDIR)/usr/sbin && \
	    install -m 755 $(INADYN_BDIR)/src/inadyn-mt \
		$(INADYN_INSTDIR)/usr/sbin/inadyn && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip $(INADYN_INSTDIR)/usr/sbin/* ; }
	$(Q)(cd $(INADYN_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) inadyn-$(INADYN_VERS).tgz \
		$(call do-log,$(INADYN_BDIR)/makepkg.out) && \
	    mv inadyn-$(INADYN_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(INADYN_INSTDIR)
