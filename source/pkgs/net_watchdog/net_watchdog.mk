# Package: NET_WATCHDOG
NET_WATCHDOG_SDIR   = $(SOURCES_DIR)/pkgs/net_watchdog
NET_WATCHDOG_BDIR    = $(PKGBUILD_DIR)/net_watchdog/build
NET_WATCHDOG_ITEMS  = $(NET_WATCHDOG_SDIR)/net_watchdog.sh
NET_WATCHDOG_DIR    = $(PKGBUILD_DIR)/net_watchdog
NET_WATCHDOG_INSTDIR= $(PKGINST_DIR)/net_watchdog

NET_WATCHDOG_RELIES = $(call patch-dep, $(NET_WATCHDOG_ITEMS))
NET_WATCHDOG_RELIES += $(call mk-dep,$(NET_WATCHDOG_SDIR)/net_watchdog.mk)

PHONY += net_watchdog net_watchdog-dirclean net_watchdog-clean

net_watchdog: toolchain $(NET_WATCHDOG_DIR)/.posthostinst

$(eval $(call create-install-targs,net_watchdog,NET_WATCHDOG))

$(NET_WATCHDOG_DIR)/.built: $(NET_WATCHDOG_RELIES) $(TOOLCHAIN_DIR)/.toolchain
	$(call print-info,[BUILD] NET_WATCHDOG target utility)
	$(Q)mkdir -p $(NET_WATCHDOG_DIR) && mkdir -p $(NET_WATCHDOG_BDIR)
	$(Q)touch $@

$(NET_WATCHDOG_DIR)/.hostinst: $(NET_WATCHDOG_DIR)/.built
	$(Q)touch $@

$(NET_WATCHDOG_DIR)/.posthostinst: $(NET_WATCHDOG_DIR)/.hostinst
	$(Q){ rm -rf $(NET_WATCHDOG_INSTDIR) && \
	mkdir -p $(NET_WATCHDOG_INSTDIR)/usr/bin && \
          $(CP) $(NET_WATCHDOG_SDIR)/net_watchdog.sh $(NET_WATCHDOG_INSTDIR)/usr/bin/ && \
          chmod 755 $(NET_WATCHDOG_INSTDIR)/usr/bin/net_watchdog.sh ; \
        }
	$(Q)(cd $(NET_WATCHDOG_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) net_watchdog.tgz \
                $(call do-log,$(NET_WATCHDOG_BDIR)/makepkg.out) && \
	    mv net_watchdog.tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(NET_WATCHDOG_INSTDIR)
	$(call autoclean,net_watchdog-clean)
	$(Q)touch $@

#        mkdir -p $(NET_WATCHDOG_INSTDIR)/etc && \
#          $(CP) $(NET_WATCHDOG_SDIR)/net_watchdog.conf $(NET_WATCHDOG_INSTDIR)/etc ;\

net_watchdog-dirclean:

net_watchdog-clean:
	$(Q)-rm -rf $(NET_WATCHDOG_DIR)
