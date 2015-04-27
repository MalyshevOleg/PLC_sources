# Package: ALSA-UTILS
ALSA-UTILS_VERS = 1.0.24.2
ALSA-UTILS_EXT  = tar.bz2
#ALSA-UTILS_SITE = ftp://ftp.alsa-project.org/pub/utils
ALSA-UTILS_SITE = http://sources.buildroot.net
ALSA-UTILS_PDIR = pkgs/alsa-utils

ALSA-UTILS_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc
ALSA-UTILS_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr \
    --with-curses=ncursesw \
    --disable-xmlto \
    --disable-nls

ALSA-UTILS_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

ALSA-UTILS_RUNTIME_INSTALL = y
ALSA-UTILS_DEPS = ALSA-LIB NCURSES

ALSA-UTILS_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) alsa-utils-rt) \
    $(call autoclean,alsa-utils-dirclean)

$(eval $(call create-common-defs,alsa-utils,ALSA-UTILS,-))

$(ALSA-UTILS_DIR)/.hostinst: $(ALSA-UTILS_DIR)/.built
	$(Q)touch $@

alsa-utils-rt:
	$(Q){ rm -rf $(ALSA-UTILS_INSTDIR) && \
	mkdir -p $(ALSA-UTILS_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(ALSA-UTILS_BDIR) \
	    STRIPPROG=$(TARGET)-strip DESTDIR=$(ALSA-UTILS_INSTDIR) \
	    install \
	    $(call do-log,$(ALSA-UTILS_BDIR)/posthostinst.out); }
	$(Q){ cd $(ALSA-UTILS_INSTDIR); rm -rf usr/share/man; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all usr/sbin/alsactl usr/bin/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) alsa-utils-$(ALSA-UTILS_VERS).tgz \
		$(call do-log,$(ALSA-UTILS_BDIR)/makepkg.out) && \
	    mv alsa-utils-$(ALSA-UTILS_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;}
	$(Q)rm -rf $(ALSA-UTILS_INSTDIR)
