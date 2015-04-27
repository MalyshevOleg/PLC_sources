# Package: GLIB
GLIB_VERS = 2.22.5
GLIB_EXT  = tar.bz2
GLIB_SITE = http://ftp.gtk.org/pub/glib/2.22
GLIB_PDIR = pkgs/glib

GLIB_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2" CC=$(TARGET)-gcc \
    glib_cv_stack_grows=no \
    glib_cv_uscore=yes \
    ac_cv_func_posix_getpwuid_r=yes \
    ac_cv_func_posix_getgrgid_r=yes
GLIB_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib \
    --mandir=$(TARGET_DIR)/share/man \
    --with-headers=$(PKGBUILD_DIR)/linux-$(LINUX_VERS)/$(BUILDCONF)/include \
    --enable-shared \
    --disable-static \
    --disable-gtk-doc-html

GLIB_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

GLIB_TO_DEL = glib-* gtester* gobject*
GLIB_DIRS2DEL = gdb glib-2.0 gtk-doc locale

GLIB_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)
GLIB_EXTRA_INSTALL = $(Q)$(SUDO) rm -f $(addprefix \
    $(TARGET_DIR)/bin/,$(GLIB_TO_DEL)) && \
    $(SUDO) rm -rf $(addprefix $(TARGET_DIR)/share/,$(GLIB_DIRS2DEL))

GLIB_RUNTIME_INSTALL = y
GLIB_DEPS = TOOLCHAIN

GLIB_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) glib-rt) \
    $(call autoclean,glib-dirclean)

$(eval $(call create-common-defs,glib,GLIB,-))

glib-rt:
	$(Q){ rm -rf $(GLIB_INSTDIR) && \
	mkdir -p $(GLIB_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(GLIB_BDIR) DESTDIR=$(GLIB_INSTDIR) \
	    install \
	    $(call do-log,$(GLIB_BDIR)/posthostinst.out); }
	$(Q)(cd $(GLIB_INSTDIR)/$(TARGET_DIR)/$(TARGET); \
	    rm -f lib/*.a lib/*.la; \
	    rm -rf lib/glib-2.0 lib/pkgconfig; \
	    rm -rf include share ; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) glib-$(GLIB_VERS).tgz \
		$(call do-log,$(GLIB_BDIR)/makepkg.out) && \
	    mv glib-$(GLIB_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(GLIB_INSTDIR)
