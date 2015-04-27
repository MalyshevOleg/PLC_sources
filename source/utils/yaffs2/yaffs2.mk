# Package: YAFFS2
YAFFS2_VERS = 1.0
YAFFS2_EXT  = tar.bz2
YAFFS2_PDIR = utils/yaffs2
YAFFS2_SITE = file://$(SOURCES_DIR)/$(YAFFS2_PDIR)

YAFFS2_DEPS = TOOLCHAIN

YAFFS2_POSTHOSTINST = \
    $(call autoclean,yaffs2-dirclean)

YAFFS2_BINS = $(YAFFS2_BDIR)/utils/mkyaffs2image \
    $(YAFFS2_BDIR)/utils/mkyaffsimage

$(eval $(call create-common-defs,yaffs2,YAFFS2,-))

$(YAFFS2_DIR)/.configured: $(YAFFS2_STEPS_DIR)/.patched
	$(call print-info,configuring YAFFS2 $(YAFFS2_VERS))
	$(Q)mkdir -p $(YAFFS2_BDIR) && cd $(YAFFS2_BDIR) && \
	    lndir $(YAFFS2_SDIR) > /dev/null
	$(Q)touch $@

$(YAFFS2_DIR)/.built: $(YAFFS2_DIR)/.configured
	$(call print-info,building  YAFFS2 $(YAFFS2_VERS))
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(YAFFS2_BDIR)/utils \
	    mkyaffs2image mkyaffsimage \
	    $(call do-log,$(YAFFS2_BDIR)/make.out)
	$(Q)touch $@

$(YAFFS2_DIR)/.hostinst: $(YAFFS2_DIR)/.built
	$(call print-info,installing YAFFS2 $(YAFFS2_VERS) to host)
	$(Q)$(SUDO) $(CP) $(YAFFS2_BINS) $(TARGET_DIR)/bin/ \
	    $(call do-log,$(YAFFS2_BDIR)/hostinstall.out)
	$(Q)touch $@
