#############################################################
#
# jpeg (libraries needed by some apps)
#
#############################################################
# TODO remove .la from /lib

JPEG_VERS = 8d
#JPEG_SITE = http://www.ijg.org/files/
JPEG_SITE = file://$(SOURCES_DIR)/$(JPEG_PDIR)
JPEG_EXT  = tar.gz
# исходный путь к пакету (внутри source)
JPEG_PDIR = pkgs/jpeg

# Запуск autogen.sh
JPEG_CONFIG_VARS =  PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc

# Конфигурирование переменных для autogen.sh
JPEG_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib 

# задание дополнительных переменных для make
JPEG_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

JPEG_RUNTIME_INSTALL = y
# Пакет от которого зависит - toolchain
JPEG_DEPS = TOOLCHAIN

JPEG_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) jpeg-rt) \
    $(call autoclean,jpeg-dirclean)

#  Выполняет команды create-common-vars, create-common-targs 
$(eval $(call create-common-defs,jpeg,JPEG,-))

JPEG_INSTALL_TARGET = install-exec install-data

jpeg-rt:
	$(Q){ rm -rf $(JPEG_INSTDIR) && \
	    mkdir -p $(JPEG_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(JPEG_BDIR) DESTDIR=$(JPEG_INSTDIR) \
	    libdir=/lib bindir=/usr/bin includedir=/usr/include \
	    install-strip \
	    $(call do-log,$(JPEG_BDIR)/posthostinst.out); \
	    echo "--Completed--" $(PWD)
	     }
	$(Q)(cd $(JPEG_INSTDIR); \
	    rm -rf usr/include lib/pkgconfig; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) jpeg-$(JPEG_VERS).tgz \
	    $(call do-log,$(JPEG_BDIR)/makepkg.out) && \
	    mv jpeg-$(JPEG_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(JPEG_INSTDIR)
