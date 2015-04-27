# Package: GDB
GDB_VERS = 7.4.1
GDB_EXT  = tar.bz2
GDB_SITE = ftp://ftp.gnu.org/gnu/gdb
GDB_PDIR = pkgs/gdb

GDB_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-O2" CC=$(TARGET)-gcc
GDB_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr \
    --without-x \
    --disable-sim \
    --disable-tui \
    --disable-gdbtk \
    --enable-gdbserver \
    --enable-threads \
    --without-included-gettext \
    --without-uiout

GDB_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

GDB_RUNTIME_INSTALL = y
GDB_DEPS = TERMCAP

GDB_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) gdb-rt) \
    $(call autoclean,gdb-dirclean)

$(eval $(call create-common-defs,gdb,GDB,-))

GDB_BDIRHOST = $(GDB_DIR)/buildhost

$(GDB_DIR)/.configured: $(GDB_DIR)/.host.hostinst

$(GDB_DIR)/.hostinst: $(GDB_DIR)/.built
	$(Q)touch $@

gdb-rt:
	$(Q){ rm -rf $(GDB_INSTDIR) && \
	mkdir -p $(GDB_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(GDB_BDIR) DESTDIR=$(GDB_INSTDIR) \
	    install \
	    $(call do-log,$(GDB_BDIR)/posthostinst.out); }
	$(Q)(cd $(GDB_INSTDIR); \
	    rm -rf usr/include usr/info usr/lib usr/man usr/share; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) gdb-$(GDB_VERS).tgz \
		$(call do-log,$(GDB_BDIR)/makepkg.out) && \
	    mv gdb-$(GDB_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(GDB_INSTDIR)

$(GDB_DIR)/.host.configured: $(GDB_STEPS_DIR)/.patched
	$(call print-info,[CONFG] GDB for host $(GDB_VERS))
	$(Q)mkdir -p $(GDB_BDIRHOST) && cd $(GDB_BDIRHOST) && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    CFLAGS="-O2" \
	    $(GDB_SDIR)/$(CONFIGURE) \
	    --build=$(HOST_CPU) \
	    --host=$(HOST_CPU) \
	    --target=$(TARGET) \
	    --prefix=$(TARGET_DIR)/$(TARGET) \
	    --bindir=$(TARGET_DIR)/bin \
	    --datadir=$(TARGET_DIR)/share \
	    --infodir=$(TARGET_DIR)/share/info \
	    --mandir=$(TARGET_DIR)/share/man \
	    --without-x \
	    --disable-sim \
	    --disable-gdbtk \
	    --disable-gdbserver \
	    --without-included-gettext \
	    --without-uiout $(call do-log,$(GDB_BDIRHOST)/configure.out)
	$(Q)touch $@

$(GDB_DIR)/.host.built: $(GDB_DIR)/.host.configured
	$(call print-info,[BUILD] GDB for host $(GDB_VERS))
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(GDB_BDIRHOST) \
	    $(call do-log,$(GDB_BDIRHOST)/make.out)
	$(Q)touch $@

$(GDB_DIR)/.host.hostinst: $(GDB_DIR)/.host.built
	$(call print-info,[INSTL] GDB for host $(GDB_VERS))
	$(Q)$(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH) \
	    $(MAKE) -C $(GDB_BDIRHOST) install \
	    $(call do-log,$(GDB_BDIRHOST)/hostinstall.out)
	$(Q)($(SUDO) strip $(TARGET_DIR)/bin/$(TARGET)-gdb && \
	    if [ -f $(TARGET_DIR)/$(TARGET)/bin/gdb ]; then \
	    $(SUDO) rm $(TARGET_DIR)/$(TARGET)/bin/gdb; fi && \
	    $(SUDO) ln -s ../../bin/$(TARGET)-gdb \
		$(TARGET_DIR)/$(TARGET)/bin/gdb)
	$(Q)$(SUDO) gzip -9f $(TARGET_DIR)/share/man/*/*.? && \
	    find $(TARGET_DIR)/share/info -name '*.info*' \
	    ! -name '*.gz' | xargs $(SUDO) gzip -9f
	$(Q)$(call autoclean,gdb-dirclean)
	$(Q)touch $@
