# Package: PKGTOOLS
PKGTOOLS_ITEMS  = makepkg installpkg
PKGTOOLS_SITE   = http://slackware.mirrors.tds.net/pub/slackware/slackware_source/a/pkgtools/scripts
PKGTOOLS_SDIR   = $(SOURCES_DIR)/utils/pkgtools
PKGTOOLS_DIR    = $(PKGBUILD_DIR)/pkgtools
PKGTOOLS_RELIES = $(call patch-dep,\
    $(addprefix $(PKGTOOLS_SDIR)/,$(PKGTOOLS_ITEMS)))
PKGTOOLS_RELIES += $(call mk-dep,$(PKGTOOLS_SDIR)/pkgtools.mk)
PKGTOOLS_PHOST_INSTALL = $(PKGTOOLS_DIR)/.hostinst

pkgtools: tar $(PKGTOOLS_DIR)/.hostinst

$(PKGTOOLS_DIR)/.hostinst: $(PKGTOOLS_RELIES)
	$(call print-info,[INSTL] PKGTOOLS)
	$(Q)cd $(PKGTOOLS_SDIR) && mkdir -p $(PKGTOOLS_DIR) && \
	$(SUDO) mkdir -p $(TARGET_DIR)/bin && \
	for item in $(PKGTOOLS_ITEMS); do \
	    $(SUDO) $(CP) $$item $(TARGET_DIR)/bin; \
	    $(SUDO) chmod a+x $(TARGET_DIR)/bin/$$item; \
	done
	$(Q)touch $@
