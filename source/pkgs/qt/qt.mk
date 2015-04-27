# Package: QT
QT_VERS = 4.8.5
QT_EXT  = tar.gz
#QT_SITE = http://download.qt-project.org/official_releases/qt/4.8/4.8.5/
QT_SITE = http://pkgs.fedoraproject.org/repo/pkgs/qt/qt-everywhere-opensource-src-4.8.5.tar.gz/1864987bdbb2f58f8ae8b350dfdbe133/
QT_PDIR = pkgs/qt

ifeq "$(MACH)" "s3c"
QT_ARCH_OPTS = -xplatform qws/linux-arm-s3c -no-opengl
QT_DEPS = GSTPLUGINS_BASE TSLIB
else ifeq "$(MACH)" "qemu"
QT_ARCH_OPTS = -xplatform qws/linux-arm-s3c -qt-kbd-linuxinput \
                -no-opengl -webkit
QT_DEPS = GSTPLUGINS_BASE TSLIB
else ifeq "$(MACH)" "at91"
QT_ARCH_OPTS = -xplatform qws/linux-at91sam926x \
    -plugin-mouse-AT91SAM926xMouse \
    -plugin-kbd-AT91SAM926xKbd \
    -DMACHAT91 \
    -DQT_QWS_ROTATE_BGR \
    -no-opengl
QT_DEPS = GSTPLUGINS_BASE DBUS TSLIB
else ifeq "$(MACH)" "am35"
QT_ARCH_OPTS = -xplatform qws/linux-omap3-g++ \
    -opengl es2 \
    -plugin-gfx-powervr \
    -DQT_QWS_CLIENTBLIT \
    -plugin-kbd-AT91SAM926xKbd \
    -webkit
QT_DEPS = GSTPLUGINS_BASE DBUS TSLIB GFX
else
QT_ARCH_OPTS =
QT_DEPS =
endif

#    -DQT_NO_QWS_CURSOR - for TI skipped

QT_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    PKG_CONFIG_PATH=$(TARGET_DIR)/$(TARGET)/lib/pkgconfig 


QT_CONFIG_OPTS = \
    -v \
    -prefix / \
    -force-pkg-config \
    -crossarch arm \
    -embedded arm \
    -confirm-license \
    -no-largefile \
    -no-qt3support \
    -depths 16,24,32 \
    -qt-gfx-linuxfb \
    -qt-gfx-transformed \
    -no-gfx-qvfb \
    -no-gfx-vnc \
    -no-gfx-multiscreen \
    -no-mouse-pc \
    -no-mouse-linuxtp \
    -no-mouse-qnx \
    -qt-mouse-tslib \
    -no-mouse-qvfb \
    -release \
    -shared \
    -little-endian \
    -qt-libmng \
    -qt-zlib \
    -qt-libjpeg \
    -qt-libpng \
    -no-libtiff \
    -qt-freetype \
    -no-openssl \
    -no-sql-sqlite \
    -no-xmlpatterns \
    -phonon \
    -svg \
    -no-stl \
    -no-cups \
    -no-nis \
    -fast \
    -no-pch \
    -no-rpath \
    -make examples \
    -make demos \
    -opensource \
    $(QT_ARCH_OPTS)

QT_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CC=$(TARGET)-gcc

QT_RUNTIME_INSTALL = y

QT_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)
QT_EXTRA_INSTALL = $(Q){ $(SED) -i \
    -e 's,tion=\(.*\)\(uic\|moc\),tion=$${prefix}/bin/\2,' \
    -e 's,include$${prefix},include/,' \
    -e 's,$${prefix}$${prefix},$${prefix}/,' \
    -e 's,//,$${prefix}/,g' \
    -e 's,-L/usr/X11R6/lib ,,' \
    -e 's,-L$(TARGET_DIR)/$(TARGET)/lib ,,' \
    -e 's,^prefix=.*,prefix=$(TARGET_DIR)/$(TARGET),' \
$(TARGET_DIR)/$(TARGET)/lib/pkgconfig/Qt*.pc \
$(TARGET_DIR)/$(TARGET)/lib/pkgconfig/phonon.pc && \
$(SED) -i \
    -e 's,//,$(TARGET_DIR)/$(TARGET)/,g' \
    -e 's,-L/usr/X11R6/lib ,,' \
    -e "s,^libdir=.*,libdir='$(TARGET_DIR)/$(TARGET)/lib'," \
$(TARGET_DIR)/$(TARGET)/lib/libQ*.la $(TARGET_DIR)/$(TARGET)/lib/*.prl \
$(TARGET_DIR)/$(TARGET)/lib/libphonon.la ;}

QT_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) qt-rt) \
    $(call autoclean,qt-dirclean)

$(eval $(call create-common-vars,qt,QT,-))
QT_SRC  = qt-everywhere-opensource-src-$(QT_VERS).$(QT_EXT)
QT_SDIR = $(PKGSOURCE_DIR)/qt-everywhere-opensource-src-$(QT_VERS)
QT_STEPS_DIR  = $(PKGSTEPS_DIR)/qt-everywhere-opensource-src-$(QT_VERS)
QT_DIR  = $(PKGBUILD_DIR)/qt-everywhere-opensource-src-$(QT_VERS)
QT_DL_DIR = $(DOWNLOAD_DIR)/qt-everywhere-opensource-src-$(QT_VERS)
$(eval $(call create-common-targs,qt,QT))
$(eval $(call create-install-targs,qt,QT))

QT_INSTALL_TARGET = INSTALL_ROOT=$(TARGET_DIR)/$(TARGET) install

qt-rt:
	$(Q){ rm -rf $(QT_INSTDIR) && \
	mkdir -p $(QT_INSTDIR)/lib && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(QT_BDIR) INSTALL_ROOT=$(QT_INSTDIR) \
	    install \
	    $(call do-log,$(QT_BDIR)/posthostinst.out); }
	$(Q)(cd $(QT_INSTDIR); \
	    rm -rf bin include mkspecs translations \
		demos examples lib/pkgconfig; \
	    rm -f lib/*.prl lib/*.la; \
	    ls -d lib/* | grep -v "libQt[CGNOWDX]" | grep -v "libpvr*" | grep -v "libphonon*" | \
		grep -v "fonts" | xargs rm; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all lib/*so*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) qt-everywhere-opensource-src-$(QT_VERS).tgz \
		$(call do-log,$(QT_BDIR)/makepkg.out) && \
	    mv qt-everywhere-opensource-src-$(QT_VERS).tgz \
		$(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(QT_INSTDIR)
