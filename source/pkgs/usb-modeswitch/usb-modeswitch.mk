
USB_MODESWITCH_VERS = 2.2.1
USB_MODESWITCH_DATA_VERS = 20140529

USB_MODESWITCH_EXT  = tar.bz2
USB_MODESWITCH_SITE = http://www.draisberghof.de/usb_modeswitch/
USB_MODESWITCH_PDIR = pkgs/usb-modeswitch

USB_MODESWITCH_DATA = usb-modeswitch-data-$(USB_MODESWITCH_DATA_VERS).$(USB_MODESWITCH_EXT)

USB_MODESWITCH_FILES = $(USB_MODESWITCH_DATA)

USB_MODESWITCH_DATA_DIR = $(USB_MODESWITCH_SDIR)
USB_MODESWITCH_DATA_BDIR = $(USB_MODESWITCH_BDIR)/usb-modeswitch-data-$(USB_MODESWITCH_DATA_VERS)

USB_MODESWITCH_MAKE_VARS = 	PATH=$(TARGET_DIR)/bin:$$PATH \
				CC=$(TARGET)-gcc CFLAGS="-I./ -I$(TARGET_DIR)/$(TARGET)/include/libusb-1.0 -lusb-1.0"

USB_MODESWITCH_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

USB_MODESWITCH_PKGDIR = $(SOURCES_DIR)/$(USB_MODESWITCH_PDIR)

USB_MODESWITCH_ITEMS = files/usbtty.c \
			files/ifw.c

USB_MODESWITCH_RELIES = $(call patch-dep,$(addprefix $(USB_MODESWITCH_PKGDIR)/,$(USB_MODESWITCH_ITEMS)))
USB_MODESWITCH_RELIES += $(call mk-dep,$(USB_MODESWITCH_PKGDIR)/usb-modeswitch.mk)

USB_MODESWITCH_RUNTIME_INSTALL = y
USB_MODESWITCH_DEPS = LIBUSBX IPROUTE2

$(eval $(call create-common-defs,usb-modeswitch,USB_MODESWITCH,-))

USB_MODESWITCH_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) usb-modeswitch-rt) \
                              $(call autoclean,usb-modeswitch-dirclean)

$(USB_MODESWITCH_DIR)/.configured: $(USB_MODESWITCH_STEPS_DIR)/.patched
	$(call print-info,[CONFG] USB_MODESWITCH $(USB_MODESWITCH_VERS))
	$(Q){ mkdir -p $(USB_MODESWITCH_DATA_DIR); $(INFLATE$(suffix $(USB_MODESWITCH_DATA))) $(USB_MODESWITCH_DL_DIR)/$(USB_MODESWITCH_DATA) | \
	    $(TAR) -C $(USB_MODESWITCH_DATA_DIR) $(UNTAR_OPTS) - ; }
	$(Q)mkdir -p $(USB_MODESWITCH_BDIR) && cd $(USB_MODESWITCH_BDIR) && \
		lndir $(USB_MODESWITCH_SDIR) > /dev/null
	$(Q)touch $@

$(USB_MODESWITCH_DIR)/.built: $(USB_MODESWITCH_RELIES) $(USB_MODESWITCH_DIR)/.configured
	$(call print-info,[BUILD] USB_MODESWITCH $(USB_MODESWITCH_VERS))
	$(Q)$(MAKE) -C $(USB_MODESWITCH_BDIR) $(USB_MODESWITCH_MAKE_VARS) static $(call do-log,$(USB_MODESWITCH_BDIR)/make.out)
	$(call print-info,[BUILD] USB_MODESWITCH_DATA $(USB_MODESWITCH_DATA_VERS))
	$(Q)$(MAKE) -C $(USB_MODESWITCH_DATA_BDIR) $(call do-log,$(USB_MODESWITCH_BDIR)/make-data.out)
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH $(TARGET)-gcc -O2 -o $(USB_MODESWITCH_BDIR)/usbtty $(USB_MODESWITCH_PKGDIR)/files/usbtty.c \
		$(call do-log,$(USB_MODESWITCH_BDIR)/make.out)
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH $(TARGET)-gcc -O2 -o $(USB_MODESWITCH_BDIR)/ifw $(USB_MODESWITCH_PKGDIR)/files/ifw.c \
		$(call do-log,$(USB_MODESWITCH_BDIR)/make.out)
	$(Q)touch $@

$(USB_MODESWITCH_DIR)/.hostinst: $(USB_MODESWITCH_DIR)/.built
	$(Q)touch $@

usb-modeswitch-rt:
	$(Q){	rm -rf $(USB_MODESWITCH_INSTDIR) && \
	      	mkdir -p $(USB_MODESWITCH_INSTDIR) && \
		CC=$(TARGET)-gcc $(MAKE) -C $(USB_MODESWITCH_BDIR) DESTDIR=$(USB_MODESWITCH_INSTDIR) install-static \
		$(call do-log,$(USB_MODESWITCH_BDIR)/posthostinst.out); }
	$(Q){	CC=$(TARGET)-gcc $(MAKE) -C $(USB_MODESWITCH_DATA_BDIR) DESTDIR=$(USB_MODESWITCH_INSTDIR) install \
		$(call do-log,$(USB_MODESWITCH_BDIR)/posthostinst.out); }
	$(Q)install $(USB_MODESWITCH_BDIR)/usbtty $(USB_MODESWITCH_INSTDIR)/usr/sbin
	$(Q)(   cd $(USB_MODESWITCH_INSTDIR); rm -rf usr/share/man var lib usr/sbin/usb_modeswitch_dispatcher etc; \
                $(TARGET)-strip --strip-all usr/sbin/* 2>/dev/null; \
		$(MAKEPKG) usb-modeswitch-$(USB_MODESWITCH_VERS).tgz \
		$(call do-log,$(USB_MODESWITCH_BDIR)/makepkg.out) && \
		mv usb-modeswitch-$(USB_MODESWITCH_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ )
	$(Q)rm -rf $(USB_MODESWITCH_INSTDIR)
