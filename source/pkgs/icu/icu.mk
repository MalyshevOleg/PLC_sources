# Package: ICU
ICU_VERS = 51.2
ICU_EXT  = tar.gz
ICU_PDIR = pkgs/icu
ICU_SITE = file://$(SOURCES_DIR)/$(ICU_PDIR)

ICU_BDIRHOST = $(ICU_DIR)/buildhost

ICU_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$(ICU_BDIRHOST)/bin:$$PATH CFLAGS="-O1" CXXFLAGS=" " CC=$(TARGET)-gcc
ICU_CONFIG_OPTS = \
	--build=$(HOST_CPU) \
	--host=$(TARGET) \
	--target=$(TARGET) \
	--prefix=$(TARGET_DIR) \
	--includedir=$(TARGET_DIR)/$(TARGET)/include \
	--libdir=$(TARGET_DIR)/$(TARGET)/lib \
	--mandir=$(TARGET_DIR)/share/man \
	--oldincludedir=$(TARGET_DIR)/$(TARGET)/include \
	--with-cross-build=$(ICU_BDIRHOST) --disable-samples \
	--disable-tests

ICU_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH TARGET=""
ICU_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH TARGET="")

ICU_RUNTIME_INSTALL = y
ICU_DEPS = TOOLCHAIN

ICU_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) icu-rt) \
    $(call autoclean,icu-dirclean)

$(eval $(call create-common-defs,icu,ICU,-))
ICU_SDIR=$(PKGSOURCE_DIR)/icu

$(ICU_DIR)/.configured: $(ICU_DIR)/.host.built
	$(call print-info,[CONFG] ICU $(ICU_VERS))
	$(Q)mkdir -p $(ICU_BDIR) && cd $(ICU_BDIR) && \
	    $(ICU_CONFIG_VARS) \
	    $(ICU_SDIR)/source/$(CONFIGURE) $(ICU_CONFIG_OPTS) \
	    $(call do-log,$(ICU_BDIR)/configure.out)
	$(Q)touch $@

icu-rt:
	$(Q){ rm -rf $(ICU_INSTDIR) && \
	mkdir -p $(ICU_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH TARGET="" \
	    $(MAKE) -C $(ICU_BDIR) DESTDIR=$(ICU_INSTDIR) \
	    install \
	    $(call do-log,$(ICU_BDIR)/posthostinst.out); }
	$(Q)(cd $(ICU_INSTDIR)/$(TARGET_DIR)/$(TARGET); \
	    rm -f lib/*.la; rm -rf include lib/pkgconfig; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) icu-$(ICU_VERS).tgz \
		$(call do-log,$(ICU_BDIR)/makepkg.out) && \
	    mv icu-$(ICU_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(ICU_INSTDIR)

$(ICU_DIR)/.host.configured: $(ICU_STEPS_DIR)/.patched
	$(call print-info,[CONFG] ICU for host $(ICU_VERS))
	$(Q)mkdir -p $(ICU_BDIRHOST) && cd $(ICU_BDIRHOST) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    CFLAGS="-O1" \
	    CXXFLAGS="-O1" \
	    $(ICU_SDIR)/source/$(CONFIGURE) \
	    --build=$(HOST_CPU) \
	    --host=$(HOST_CPU) \
	    --target=$(TARGET) \
	    --prefix=$(TARGET_DIR)/$(TARGET) \
	    --bindir=$(TARGET_DIR)/bin \
	    --datadir=$(TARGET_DIR)/share \
	    --infodir=$(TARGET_DIR)/share/info \
	    --mandir=$(TARGET_DIR)/share/man \
	    --disable-samples \
	    --disable-tests \
	    --disable-extras \
	    --disable-icuio \
	    --disable-layout \
	    --disable-renaming \
	    $(call do-log,$(ICU_BDIRHOST)/configure.out)
	$(Q)touch $@

$(ICU_DIR)/.host.built: $(ICU_DIR)/.host.configured
	$(call print-info,[BUILD] ICU for host $(ICU_VERS))
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	    TARGET="" \
	    $(MAKE) -C $(ICU_BDIRHOST) \
	    $(call do-log,$(ICU_BDIRHOST)/make.out)
	$(Q)touch $@
