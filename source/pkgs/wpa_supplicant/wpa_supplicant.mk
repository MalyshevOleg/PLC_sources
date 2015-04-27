# Package: WPA_SUPPLICANT
WPA_SUPPLICANT_VERS = 2.0
WPA_SUPPLICANT_EXT  = tar.gz
WPA_SUPPLICANT_SITE = http://hostap.epitest.fi/releases/
WPA_SUPPLICANT_PDIR = pkgs/wpa_supplicant

WPA_SUPPLICANT_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CC=$(TARGET_DIR)/bin/$(TARGET)-gcc CFLAGS="-Os -I$(TARGET_DIR)/$(TARGET)/include/libnl3/ -L$(TARGET_DIR)/$(TARGET)/lib" LIBS="-lssl"
#WPA_SUPPLICANT_MAKE_TARGS = CC=$(TARGET_DIR)/bin/$(TARGET)-gcc CFLAGS="-Os -I$(TARGET_DIR)/$(TARGET)/include/libnl3/ -L$(TARGET_DIR)/$(TARGET)/lib" LIBS="-lssl"
WPA_SUPPLICANT_RUNTIME_INSTALL = y
WPA_SUPPLICANT_DEPS = libnl



WPA_SUPPLICANT_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) wpa_supplicant-rt) \
    $(call autoclean,wpa_supplicant-dirclean)

$(eval $(call create-common-defs,wpa_supplicant,WPA_SUPPLICANT,-))

$(WPA_SUPPLICANT_DIR)/.configured: $(WPA_SUPPLICANT_STEPS_DIR)/.patched
	$(call print-info,[CONFG] WPA_SUPPLICANT $(WPA_SUPPLICANT_VERS))
	$(Q)mkdir -p $(WPA_SUPPLICANT_BDIR) && \
		cd $(WPA_SUPPLICANT_BDIR) && \
		lndir $(WPA_SUPPLICANT_SDIR) > /dev/null && \
		$(CP) $(WPA_SUPPLICANT_PATCH_DIR)/default-config.conf $(WPA_SUPPLICANT_BDIR)/wpa_supplicant/.config && \
		echo -e "all:\n\t$(MAKE) -C wpa_supplicant" >$(WPA_SUPPLICANT_BDIR)/Makefile
	$(Q)touch $@

$(WPA_SUPPLICANT_DIR)/.hostinst: $(WPA_SUPPLICANT_DIR)/.built
	$(Q)touch $@

wpa_supplicant-rt:
	$(Q){ rm -rf $(WPA_SUPPLICANT_INSTDIR) && \
	  install -d $(WPA_SUPPLICANT_INSTDIR)/sbin && \
	  install -d $(WPA_SUPPLICANT_INSTDIR)/etc/wpa_supplicant && \
	  $(TARGET)-strip $(WPA_SUPPLICANT_BDIR)/wpa_supplicant/wpa_supplicant $(WPA_SUPPLICANT_BDIR)/wpa_supplicant/wpa_passphrase $(WPA_SUPPLICANT_BDIR)/wpa_supplicant/wpa_cli && \
	  install $(WPA_SUPPLICANT_BDIR)/wpa_supplicant/wpa_supplicant $(WPA_SUPPLICANT_INSTDIR)/sbin && \
	  install $(WPA_SUPPLICANT_BDIR)/wpa_supplicant/wpa_passphrase $(WPA_SUPPLICANT_INSTDIR)/sbin && \
	  install $(WPA_SUPPLICANT_BDIR)/wpa_supplicant/wpa_cli $(WPA_SUPPLICANT_INSTDIR)/sbin && \
	  install -m 0600 $(WPA_SUPPLICANT_BDIR)/wpa_supplicant/wpa_supplicant.conf $(WPA_SUPPLICANT_INSTDIR)/etc/wpa_supplicant && \
	 $(call do-log,$(WPA_SUPPLICANT_BDIR)/posthostinst.out); }
	$(Q)(cd $(WPA_SUPPLICANT_INSTDIR)/; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) wpa_supplicant-$(WPA_SUPPLICANT_VERS).tgz \
		$(call do-log,$(WPA_SUPPLICANT_BDIR)/makepkg.out) && \
	    mv wpa_supplicant-$(WPA_SUPPLICANT_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(WPA_SUPPLICANT_INSTDIR)

#wpa_cli
#wpa_passphrase
#wpa_supplicant