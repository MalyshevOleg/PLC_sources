# Package: OWFS
OWFS_VERS = 2.8p8
OWFS_EXT  = tar.gz
OWFS_SITE = http://downloads.sourceforge.net/project/owfs/owfs/$(OWFS_VERS)
OWFS_PDIR = pkgs/owfs

OWFS_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-Os" CC=$(TARGET)-gcc
OWFS_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR)/$(TARGET) \
    --oldincludedir=$(TARGET_DIR)/$(TARGET)/include \
    --disable-debug \
    --disable-owshell \
    --disable-owhttpd \
    --disable-owftpd \
    --disable-owserver \
    --disable-ownet \
    --disable-owtap \
    --disable-owmon \
    --disable-owperl \
    --disable-owphp \
    --disable-owpython \
    --disable-owtcl

OWFS_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

OWFS_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

OWFS_RUNTIME_INSTALL = y
OWFS_DEPS = SNMP

OWFS_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) owfs-rt) \
    $(call autoclean,owfs-dirclean)

$(eval $(call create-common-defs,owfs,OWFS,-))

owfs-rt:
	$(Q){ rm -rf $(OWFS_INSTDIR) && \
	mkdir -p $(OWFS_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(OWFS_BDIR) DESTDIR=$(OWFS_INSTDIR) \
	    install-strip \
	    $(call do-log,$(OWFS_BDIR)/posthostinst.out); }
	$(Q)(cd $(OWFS_INSTDIR)/$(TARGET_DIR)/$(TARGET); \
	    rm -f lib/*.a lib/*.la; \
	    rm -rf include share ; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) owfs-$(OWFS_VERS).tgz \
		$(call do-log,$(OWFS_BDIR)/makepkg.out) && \
	    mv owfs-$(OWFS_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(OWFS_INSTDIR)
