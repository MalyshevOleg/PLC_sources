# Package: STRACE
STRACE_VERS = 4.6
STRACE_EXT  = tar.bz2
STRACE_SITE = http://repository.timesys.com/buildsources/s/strace/strace-4.6
STRACE_PDIR = pkgs/strace

STRACE_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-Os" CC=$(TARGET)-gcc
STRACE_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr

STRACE_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

STRACE_RUNTIME_INSTALL = y
STRACE_DEPS = TOOLCHAIN

STRACE_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) strace-rt) \
    $(call autoclean,strace-dirclean)

$(eval $(call create-common-defs,strace,STRACE,-))

$(STRACE_DIR)/.hostinst: $(STRACE_DIR)/.built
	$(Q)touch $@

strace-rt:
	$(Q){ rm -rf $(STRACE_INSTDIR) && \
	mkdir -p $(STRACE_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH DESTDIR=$(STRACE_INSTDIR) \
	    $(MAKE) -C $(STRACE_BDIR) \
	    install-binPROGRAMS \
	    $(call do-log,$(STRACE_BDIR)/posthostinst.out); }
	$(Q)(cd $(STRACE_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all usr/bin/strace; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) strace-$(STRACE_VERS).tgz \
		$(call do-log,$(STRACE_BDIR)/makepkg.out) && \
	    mv strace-$(STRACE_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(STRACE_INSTDIR)
