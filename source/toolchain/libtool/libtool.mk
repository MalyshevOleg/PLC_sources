# Package: LIBTOOL
LIBTOOL_VERS = 2.2.4
LIBTOOL_EXT  = tar.gz
LIBTOOL_SITE = http://ftp.gnu.org/gnu/libtool
LIBTOOL_PDIR = toolchain/libtool

LIBTOOL_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    --includedir=$(TARGET_DIR)/$(TARGET)/include \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib \
    --infodir=$(TARGET_DIR)/share/info

LIBTOOL_MAKE_TARGS =
LIBTOOL_INSTALL = $(SUDO)

$(eval $(call create-common-defs,libtool,LIBTOOL,-))
