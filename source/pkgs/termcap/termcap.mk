# Package: TERMCAP
TERMCAP_VERS = 1.3.1
TERMCAP_EXT  = tar.gz
TERMCAP_SITE = ftp://ftp.gnu.org/pub/gnu/termcap
TERMCAP_PDIR = pkgs/termcap

TERMCAP_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-O2 -mstructure-size-boundary=8" CC=$(TARGET)-gcc \
    AR=$(TARGET)-ar LD=$(TARGET)-ld RANLIB=$(TARGET)-ranlib \
    oldincludedir=$(TARGET_DIR)/include
TERMCAP_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR)/$(TARGET)

TERMCAP_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH all_includes=-I$(TERMCAP_BDIR)

TERMCAP_INSTALL = $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH)

TERMCAP_DEPS = TOOLCHAIN

TERMCAP_POSTHOSTINST = +$(call autoclean,termcap-dirclean)

$(eval $(call create-common-defs,termcap,TERMCAP,-))
