ftp://sourceware.org/pub/libffi/libffi-3.0.13.tar.gz

#############################################################
#
# libffi (libraries needed by some apps)
#
#############################################################
LIBFFI_VERS = 3.0.13
#LIBFFI_SITE = http://www.ijg.org/files/
LIBFFI_SITE = ftp://sourceware.org/pub/libffi
LIBFFI_EXT  = tar.gz
# исходный путь к пакету (внутри source)
LIBFFI_PDIR = pkgs/libffi

# Запуск autogen.sh
LIBFFI_CONFIG_VARS =  PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc

# Конфигурирование переменных для autogen.sh
LIBFFI_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib 

# задание дополнительных переменных для make
LIBFFI_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

LIBFFI_RUNTIME_INSTALL = y
# Пакет от которого зависит - toolchain
LIBFFI_DEPS = TOOLCHAIN

LIBFFI_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) libffi-rt) \
    $(call autoclean,libffi-dirclean)

#  Выполняет команды create-common-vars, create-common-targs 
$(eval $(call create-common-defs,libffi,LIBFFI,-))

LIBFFI_INSTALL_TARGET = install-exec install-data

libffi-rt:
	$(Q){ rm -rf $(LIBFFI_INSTDIR) && \
	    mkdir -p $(LIBFFI_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(LIBFFI_BDIR) DESTDIR=$(LIBFFI_INSTDIR) \
	    libdir=/lib bindir=/usr/bin includedir=/usr/include \
	    install-strip \
	    $(call do-log,$(LIBFFI_BDIR)/posthostinst.out); }
	$(Q)(cd $(LIBFFI_INSTDIR); \
	    rm -rf usr/include lib/pkgconfig; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) libffi-$(LIBFFI_VERS).tgz \
	    $(call do-log,$(LIBFFI_BDIR)/makepkg.out) && \
	    mv libffi-$(LIBFFI_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(LIBFFI_INSTDIR)
