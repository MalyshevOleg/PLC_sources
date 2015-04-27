# Package: OPENSSL
OPENSSL_VERS = 1.0.1
OPENSSL_EXT  = tar.gz
OPENSSL_SITE = ftp://ftp.openssl.org/source/old/1.0.1
OPENSSL_PDIR = pkgs/openssl

OPENSSL_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
OPENSSL_MAKE_TARGS = CC=$(TARGET)-gcc all

OPENSSL_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)
OPENSSL_EXTRA_INSTALL = \
    $(Q)cd $(OPENSSL_INSTDIR) && \
        $(SUDO) $(CP) include/* $(TARGET_DIR)/$(TARGET)/include && \
        $(SUDO) rm -rf $(TARGET_DIR)/$(TARGET)/lib/engines && \
        $(SUDO) rm -f $(TARGET_DIR)/$(TARGET)/lib/libcrypto.* && \
        $(SUDO) rm -f $(TARGET_DIR)/$(TARGET)/lib/libssl.* && \
        $(SUDO) $(CP) lib/* $(TARGET_DIR)/$(TARGET)/lib && \
        $(SUDO) ln -s libcrypto.so.1.0.0 $(TARGET_DIR)/$(TARGET)/lib/libcrypto.so.0 && \
        $(SUDO) ln -s libssl.so.1.0.0 $(TARGET_DIR)/$(TARGET)/lib/libssl.so.0 && \
        $(SUDO) rm -rf $(OPENSSL_INSTDIR)

OPENSSL_RUNTIME_INSTALL = y
OPENSSL_DEPS = ZLIB

OPENSSL_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) openssl-rt) \
    $(call autoclean,openssl-dirclean)

$(eval $(call create-common-defs,openssl,OPENSSL,-))

$(OPENSSL_DIR)/.configured: $(OPENSSL_STEPS_DIR)/.patched
	$(call print-info,[CONFG] OPENSSL $(OPENSSL_VERS))
	$(Q)mkdir -p $(OPENSSL_BDIR) && cd $(OPENSSL_BDIR) && \
	    lndir $(OPENSSL_SDIR) > /dev/null && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    CFLAGS="-Os" \
	    $(OPENSSL_SDIR)/Configure \
	    linux-gnueabi-arm \
	    --prefix=$(TARGET_DIR)/$(TARGET) \
	    --openssldir=/etc/ssl \
	    threads \
	    shared \
	    no-idea \
	    no-mdc2 \
	    no-rc5 \
	    zlib-dynamic $(call do-log,$(OPENSSL_BDIR)/configure.out)
	$(Q)touch $@

OPENSSL_INSTALL_TARGET = INSTALLTOP=/ \
    INSTALL_PREFIX=$(OPENSSL_INSTDIR) install_sw

openssl-rt:
	$(Q){ rm -rf $(OPENSSL_INSTDIR) && \
	mkdir -p $(OPENSSL_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(OPENSSL_BDIR) INSTALLTOP=/ \
	    INSTALL_PREFIX=$(OPENSSL_INSTDIR) \
	    install_sw \
	    $(call do-log,$(OPENSSL_BDIR)/posthostinst.out); }
	$(Q)(cd $(OPENSSL_INSTDIR); rm -rf bin include lib/pkgconfig etc/ssl/man; \
	    rm -f lib/*.a etc/ssl/misc/CA.pl etc/ssl/misc/tsget; \
	    ln -s libcrypto.so.1.0.0 lib/libcrypto.so.0; \
	    ln -s libssl.so.1.0.0 lib/libssl.so.0; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so* lib/engines/*so*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) openssl-$(OPENSSL_VERS).tgz \
		$(call do-log,$(OPENSSL_BDIR)/makepkg.out) && \
	    mv openssl-$(OPENSSL_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(OPENSSL_INSTDIR)
