# Package: NET_IDS
NET_IDS_SDIR   = $(SOURCES_DIR)/pkgs/net_ids
NET_IDS_ITEMS  = $(NET_IDS_SDIR)/net_ids.c
NET_IDS_DIR    = $(PKGBUILD_DIR)/net_ids
NET_IDS_BDIR   = $(PKGBUILD_DIR)/net_ids/build
NET_IDS_INSTDIR= $(PKGINST_DIR)/net_ids

NET_IDS_RELIES = $(call patch-dep, $(NET_IDS_ITEMS))
NET_IDS_RELIES += $(call mk-dep,$(NET_IDS_SDIR)/net_ids.mk)

PHONY += net_ids ids_login-dirclean ids_login-clean

net_ids: toolchain $(NET_IDS_DIR)/.posthostinst

$(eval $(call create-install-targs,net_ids,NET_IDS))

$(NET_IDS_DIR)/.built: $(NET_IDS_RELIES) $(TOOLCHAIN_DIR)/.toolchain
	$(call print-info,[BUILD] NET_IDS target utility)
	$(Q)mkdir -p $(NET_IDS_BDIR) && cd $(NET_IDS_BDIR) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-gcc -O2 -o net_ids $(NET_IDS_ITEMS) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-strip -s net_ids
	$(Q)touch $@

$(NET_IDS_DIR)/.hostinst: $(NET_IDS_DIR)/.built
	$(Q)touch $@

$(NET_IDS_DIR)/.posthostinst: $(NET_IDS_DIR)/.hostinst
	$(Q){ rm -rf $(NET_IDS_INSTDIR) && \
	mkdir -p $(NET_IDS_INSTDIR)/usr/bin && \
          $(CP) $(NET_IDS_BDIR)/net_ids $(NET_IDS_INSTDIR)/usr/bin/ && \
          $(CP) $(NET_IDS_SDIR)/net_ids.sh $(NET_IDS_INSTDIR)/usr/bin/ && \
          chmod 755 $(NET_IDS_INSTDIR)/usr/bin/net_ids.sh ; \
        }
	$(Q)(cd $(NET_IDS_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) net_ids.tgz \
		$(call do-log,$(NET_IDS_BDIR)/makepkg.out) && \
	    mv net_ids.tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(NET_IDS_INSTDIR)
	$(Q)$(call autoclean,net_ids-clean)
	$(Q)touch $@

#        mkdir -p $(NET_IDS_INSTDIR)/etc && \
#          $(CP) $(NET_IDS_SDIR)/net_ids.conf $(NET_IDS_INSTDIR)/etc ;\

net_ids-dirclean:
	$(Q)-rm -rf $(NET_IDS_BDIR)

net_ids-clean:
	$(Q)-rm -rf $(NET_IDS_DIR)
