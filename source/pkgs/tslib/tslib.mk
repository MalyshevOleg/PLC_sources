# Package: TSLIB
TSLIB_VERS = 1.0
TSLIB_EXT  = tar.bz2
#TSLIB_SITE = http://download.berlios.de/tslib
TSLIB_SITE = http://pkgs.fedoraproject.org/repo/pkgs/tslib/tslib-1.0.tar.bz2/92b2eb55b1e4ef7e2c0347069389390e/
TSLIB_PDIR = pkgs/tslib

TSLIB_CONFIG_VARS = \
    (cd $(TSLIB_SDIR) && PATH=$(TARGET_DIR)/bin:$$PATH ./autogen.sh \
        $(call do-log,$(TSLIB_BDIR)/configmake.out)) && \
    PATH=$(TARGET_DIR)/bin:$$PATH \
    ac_cv_func_malloc_0_nonnull=yes
TSLIB_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib \
    --with-plugindir=/usr/lib/ts \
    --sysconfdir=/etc

TSLIB_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

TSLIB_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

TSLIB_RUNTIME_INSTALL = y
TSLIB_DEPS = TOOLCHAIN

TSLIB_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) tslib-rt) \
    $(call autoclean,tslib-dirclean)

$(eval $(call create-common-defs,tslib,TSLIB,-))

TSLIB_INSTALL_TARGET = SUBDIRS=src install-exec install-data

tslib-rt:
	$(Q){ rm -rf $(TSLIB_INSTDIR) && \
	mkdir -p $(TSLIB_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(TSLIB_BDIR) DESTDIR=$(TSLIB_INSTDIR) \
	    libdir=/lib bindir=/usr/bin includedir=/usr/include \
	    install-strip \
	    $(call do-log,$(TSLIB_BDIR)/posthostinst.out); }
	$(Q)(cd $(TSLIB_INSTDIR); \
	    rm -rf usr/include lib/pkgconfig; \
	    rm -f lib/*.la usr/lib/ts/*.la; \
	    $(SED) -i -e 's/^# module_raw input/module_raw input/' \
	    etc/ts.conf; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) tslib-$(TSLIB_VERS).tgz \
		$(call do-log,$(TSLIB_BDIR)/makepkg.out) && \
	    mv tslib-$(TSLIB_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(TSLIB_INSTDIR)
