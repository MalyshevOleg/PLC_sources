# Package: MAKEDEVS
MAKEDEVS_SDIR   = $(SOURCES_DIR)/utils/makedevs
MAKEDEVS_ITEMS  = $(MAKEDEVS_SDIR)/makedevs.c
MAKEDEVS_DIR    = $(PKGBUILD_DIR)/makedevs
MAKEDEVS_BDIR   = $(PKGBUILD_DIR)/makedevs/build

MAKEDEVS_RELIES = $(call patch-dep, $(MAKEDEVS_ITEMS))
MAKEDEVS_RELIES += $(call mk-dep,$(MAKEDEVS_SDIR)/makedevs.mk)

PHONY += makedevs makedevs-native makedevs-dirclean makedevs-clean

makedevs: toolchain $(MAKEDEVS_DIR)/.makedevs

$(MAKEDEVS_DIR)/.makedevs: $(MAKEDEVS_RELIES) 
	$(call print-info,[BUILD] MAKEDEVS target utility)
	$(Q)mkdir -p $(MAKEDEVS_BDIR) && cd $(MAKEDEVS_BDIR) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-gcc -o makedevs $(MAKEDEVS_ITEMS) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(TARGET)-strip -s makedevs
	$(Q)-rm -f $(BINARIES_DIR)/arm$(MACH)-runtime/sbin/makedevs && \
	    mkdir -p $(BINARIES_DIR)/arm$(MACH)-runtime/sbin && \
	    $(CP) $(MAKEDEVS_BDIR)/makedevs \
		$(BINARIES_DIR)/arm$(MACH)-runtime/sbin/
	$(Q)$(call autoclean,makedevs-clean)
	$(Q)touch $@

makedevs-native: $(MAKEDEVS_DIR)/.makedevs-native

$(MAKEDEVS_DIR)/.makedevs-native: $(MAKEDEVS_RELIES) 
	$(call print-info,[BUILD] MAKEDEVS host utility)
	$(Q)mkdir -p $(MAKEDEVS_BDIR) && cd $(MAKEDEVS_BDIR) && \
	    $(HOST_CC) -o makedevs-native $(MAKEDEVS_ITEMS) && \
	    strip -s makedevs-native
	$(Q)$(SUDO) rm -f $(TARGET_DIR)/bin/makedevs && \
	    $(SUDO) mkdir -p $(TARGET_DIR)/bin && \
	    $(SUDO) $(CP) $(MAKEDEVS_BDIR)/makedevs-native \
		$(TARGET_DIR)/bin/makedevs
	$(Q)$(call autoclean,makedevs-clean)
	$(Q)touch $@

makedevs-dirclean:
	$(Q)-rm -rf $(MAKEDEVS_BDIR)

makedevs-clean:
	$(Q)-rm -rf $(MAKEDEVS_DIR)
