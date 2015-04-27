# Package: PLCVIEW
PLCVIEW_VERS = 1.0
PLCVIEW_EXT  = tar.bz2
PLCVIEW_PDIR = pkgs/plcview
PLCVIEW_SITE = file://$(SOURCES_DIR)/$(PLCVIEW_PDIR)

PLCVIEW_RUNTIME_INSTALL = y
PLCVIEW_DEPS = QT 

PLCVIEW_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
PLCVIEW_MAKE_TARGS = CROSSPATH= CROSS_PREFIX=$(TARGET)- QTDIR=$(QT_BDIR)

PLCVIEW_POSTHOSTINST = $(call do-fakeroot,$(MAKE) plcview-rt) \
    $(call autoclean,plcview-dirclean)

$(eval $(call create-common-defs,plcview,PLCVIEW,-))

$(PLCVIEW_DIR)/.configured: $(PLCVIEW_STEPS_DIR)/.patched
	$(call print-info,configuring PLCVIEW $(PLCVIEW_VERS))
	$(Q)mkdir -p $(PLCVIEW_BDIR) && cd $(PLCVIEW_BDIR) && \
	    QMAKESPEC=$(QT_BDIR)/mkspecs/linux-g++ $(QT_BDIR)/bin/qmake $(PLCVIEW_SDIR)/plcw.pro -o - | $(PLCVIEW_SDIR)/fixmake2 > $(PLCVIEW_BDIR)/Makefile
	$(Q)touch $@

$(PLCVIEW_DIR)/.hostinst: $(PLCVIEW_DIR)/.built
	$(Q)touch $@

plcview-rt:
	$(Q) { rm -rf $(PLCVIEW_INSTDIR )&& mkdir -p $(PLCVIEW_INSTDIR) && \
	    cd $(PLCVIEW_INSTDIR) && \
	    install -d -m 755 $(PLCVIEW_INSTDIR)/usr/bin && \
	    install -m 755 $(PLCVIEW_BDIR)/plcw \
		$(PLCVIEW_INSTDIR)/usr/bin/plcw ; }
	$(Q)(cd $(PLCVIEW_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) plcview-$(PLCVIEW_VERS).tgz \
		$(call do-log,$(PLCVIEW_BDIR)/makepkg.out) && \
	    mv plcview-$(PLCVIEW_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(PLCVIEW_INSTDIR)
