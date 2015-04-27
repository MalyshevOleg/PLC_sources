# Package: JQ
JQ_VERS = 1.4
JQ_EXT  = tar.gz
JQ_SITE = http://stedolan.github.io/jq/download/source
JQ_PDIR = pkgs/jq

JQ_CFLAGS=CFLAGS="-O2" CC=$(TARGET)-gcc

JQ_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    $(JQ_CFLAGS) \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig

JQ_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr

JQ_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
JQ_RUNTIME_INSTALL = y
JQ_DEPS = TOOLCHAIN

JQ_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) jq-rt) \
    $(call autoclean,jq-dirclean)

$(eval $(call create-common-defs,jq,JQ,-))

JQ_INSTALL_TARGET = PATH=$(TARGET_DIR)/bin:$$PATH DESTDIR=$(TARGET_DIR)/$(TARGET) install

$(JQ_DIR)/.configured: $(JQ_STEPS_DIR)/.patched
	$(call print-info,[CONFG] JQ $(JQ_VERS))
	$(Q)cd $(JQ_SDIR); autoconf -i
	$(Q)mkdir -p $(JQ_BDIR) && cd $(JQ_BDIR) && \
	    $(JQ_CONFIG_VARS) \
	    $(JQ_SDIR)/$(CONFIGURE) $(JQ_CONFIG_OPTS) \
	    $(call do-log,$(JQ_BDIR)/configure.out)
	$(Q)touch $@

$(JQ_DIR)/.hostinst: $(JQ_DIR)/.built
	$(Q)touch $@

jq-rt:
	$(Q){ rm -rf $(JQ_INSTDIR) && \
	mkdir -p $(JQ_INSTDIR) && \
	    COMPILER_PATH=$(TARGET_DIR)/bin $(JQ_CFLAGS) \
	    $(MAKE) -C $(JQ_BDIR) STRIPPROG=$(TARGET)-strip DESTDIR=$(JQ_INSTDIR) libdir=/lib install \
	    $(call do-log,$(JQ_BDIR)/posthostinst.out); }
	$(Q)(cd $(JQ_INSTDIR); rm -rf usr/share usr/include lib/*.la lib/*.a ; \
		$(TARGET)-strip --strip-all usr/bin/* lib/*; \
		$(MAKEPKG) jq-$(JQ_VERS).tgz \
		$(call do-log,$(JQ_BDIR)/makepkg.out) && \
	    mv jq-$(JQ_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(JQ_INSTDIR)
