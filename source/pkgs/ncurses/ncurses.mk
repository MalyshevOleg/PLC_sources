# Package: NCURSES
NCURSES_VERS = 5.6
NCURSES_EXT  = tar.gz
NCURSES_SITE = http://ftp.gnu.org/pub/gnu/ncurses
NCURSES_PDIR = pkgs/ncurses

NCURSES_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2" CC=$(TARGET)-gcc RANLIB=$(TARGET)-ranlib
NCURSES_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr \
    --with-terminfo-dirs=/usr/share/terminfo \
    --with-default-terminfo-dir=/usr/share/terminfo \
    --with-build-cppflags=-I/usr/include \
    --with-gpm \
    --with-normal \
    --with-shared \
    --enable-symlinks \
    --without-debug \
    --without-manpages \
    --without-profile \
    --without-tests \
    --without-ada \
    --program-suffix="" \
    --program-prefix=$(TARGET)- \
    --enable-widec

NCURSES_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

NCURSES_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

NCURSES_RUNTIME_INSTALL = y
NCURSES_DEPS = TOOLCHAIN

TO_DEL = captoinfo clear infocmp infotocap reset tic toe tput tset tack

NCURSES_EXTRA_INSTALL = $(Q)$(SUDO) rm -f $(addprefix \
    $(TARGET_DIR)/bin/$(TARGET)-,$(TO_DEL)) $(TARGET_DIR)/bin/tack && \
    $(SUDO) $(SED) -i -e '/^prefix=/s|=.*|="${TARGET_DIR}/${TARGET}"|' \
        $(TARGET_DIR)/bin/ncursesw5-config

NCURSES_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) ncurses-rt) \
    $(call autoclean,ncurses-dirclean)

$(eval $(call create-common-defs,ncurses,NCURSES,-))

NCURSES_INSTALL_TARGET = DESTDIR=$(TARGET_DIR)/$(TARGET) \
    prefix= bindir=/../bin mandir=/../share/man \
    ticdir=/share/terminfo install

ncurses-rt:
	$(Q){ rm -rf $(NCURSES_INSTDIR) && \
	mkdir -p $(NCURSES_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(NCURSES_BDIR) DESTDIR=$(NCURSES_INSTDIR) \
	    libdir=/lib install.libs install.data \
	    $(call do-log,$(NCURSES_BDIR)/posthostinst.out); }
	$(Q)(cd $(NCURSES_INSTDIR); rm -f lib/*.a lib/*.la; \
	    rm -rf usr/bin usr/include; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) ncurses-$(NCURSES_VERS).tgz \
		$(call do-log,$(NCURSES_BDIR)/makepkg.out) && \
	    mv ncurses-$(NCURSES_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(NCURSES_INSTDIR)
