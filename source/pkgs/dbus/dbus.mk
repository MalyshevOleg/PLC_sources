# Package: DBUS
DBUS_VERS = 1.4.1
DBUS_EXT  = tar.gz
DBUS_SITE = http://dbus.freedesktop.org/releases/dbus
DBUS_PDIR = pkgs/dbus

DBUS_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-Os" CC=$(TARGET)-gcc \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig \
    DBUS_DATADIR=/usr/share DBUS_BINDIR=/usr/bin \
    ac_cv_have_abstract_sockets=yes
DBUS_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR)/$(TARGET) \
    --localstatedir=/var \
    --program-prefix="" \
    --sysconfdir=/etc \
    --mandir=/share/man \
    --with-dbus-user=dbus \
    --with-dbus-daemondir=/usr/bin \
    --disable-tests \
    --disable-asserts \
    --enable-abstract-sockets \
    --disable-selinux \
    --disable-xml-docs \
    --disable-doxygen-docs \
    --disable-static \
    --enable-dnotify \
    --without-x \
    --with-xml=libxml \
    --with-init-scripts=redhat \
    --with-system-socket=/var/run/dbus/system_bus_socket \
    --with-system-pid-file=/var/run/dbus/dbus.pid

DBUS_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
DBUS_MAKE_TARGS = all

DBUS_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

#DBUS_RUNTIME_INSTALL = y
DBUS_DEPS = LIBXML2

#DBUS_POSTHOSTINST = $(call do-fakeroot,$(MAKE) dbus-rt)
DBUS_POSTHOSTINST = $(call autoclean,dbus-dirclean)

$(eval $(call create-common-defs,dbus,DBUS,-))

DBUS_INSTALL_TARGET = \
    SUBDIRS=dbus STRIPPROG=$(TARGET)-strip \
    prefix=$(TARGET_DIR)/$(TARGET) \
    install-exec-recursive install-data-recursive \
    install-data-am

dbus-rt:
	$(Q){ rm -rf $(DBUS_INSTDIR) && \
	mkdir -p $(DBUS_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(DBUS_BDIR) STRIPPROG=$(TARGET)-strip \
	    DESTDIR=$(DBUS_INSTDIR) prefix=/usr DBUS_DAEMONDIR=/usr/bin \
	    install-strip \
	    $(call do-log,$(DBUS_BDIR)/posthostinst.out); }
	$(Q)(cd $(DBUS_INSTDIR); \
	    rm -rf usr/include share usr/lib/dbus-1.0 usr/lib/pkgconfig; \
	    rm usr/lib/*.la; \
	    $(SED) -i -e \
		"s,servicehelper>\(.\+\)libexec,servicehelper>/usr/libexec," \
		 etc/dbus-1/system.conf;)
	$(Q)(cd $(DBUS_INSTDIR); \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) dbus-$(DBUS_VERS).tgz \
		$(call do-log,$(DBUS_BDIR)/makepkg.out) && \
	    mv dbus-$(DBUS_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(DBUS_INSTDIR)
