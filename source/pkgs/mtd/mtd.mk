# Package: MTD
MTD_VERS = 1.4.9
MTD_EXT  = tar.bz2
MTD_SITE = ftp://ftp.infradead.org/pub/mtd-utils
MTD_PDIR = pkgs/mtd

MTD_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
MTD_MAKE_TARGS = CROSS=$(TARGET)- WITHOUT_XATTR=1 SUBDIRS=
MTD_RUNTIME_INSTALL = y
MTD_DEPS = ZLIB LZO

MTD_INSTALL = $(SUDO)
MTD_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) mtd-rt) \
    $(call autoclean,mtd-dirclean)

$(eval $(call create-common-defs,mtd-utils,MTD,-))

MTD_INSTALL_TARGET = WITHOUT_XATTR=1 BUILDDIR=$(MTD_BDIR) \
    DESTDIR=$(TARGET_DIR) MTD_BINS=mkfs.jffs2 install-host

$(MTD_DIR)/.configured: $(MTD_STEPS_DIR)/.patched
	$(call print-info,[CONFG] MTD $(MTD_VERS))
	$(Q)mkdir -p $(MTD_BDIR) && cd $(MTD_BDIR) && \
	    lndir $(MTD_SDIR) > /dev/null
	$(Q)touch $@

$(MTD_DIR)/.built: $(MTD_DIR)/.configured
	$(call print-info,[BUILD] MTD $(MTD_VERS))
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(MTD_BDIR) CROSS=$(TARGET)- WITHOUT_XATTR=1 \
	    MTD_BINS=flash_erase UBIMK_BINS= UBI_BINS= \
	    $(call do-log,$($(PKG)_BDIR)/make.out)
	$(Q)$(MAKE) -C $(MTD_BDIR) BUILDDIR=$(MTD_BDIR) WITHOUT_XATTR=1 \
	    MTD_BINS=mkfs.jffs2 \
	    $(call do-log,$($(PKG)_BDIR)/make2.out)
	$(Q)touch $@

mtd-rt:
	$(Q){ rm -rf $(MTD_INSTDIR) && \
	mkdir -p $(MTD_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(MTD_BDIR) SBINDIR=sbin \
	    MTD_BINS=flash_erase UBIMK_BINS= UBI_BINS= \
	    DESTDIR=$(MTD_INSTDIR) CROSS=$(TARGET)- install \
	    $(call do-log,$(MTD_BDIR)/posthostinst.out); }
	$(Q){ cd $(MTD_INSTDIR) && \
	    find . ! -name "flash_erase" -a -type f -delete && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) mtd-utils-$(MTD_VERS).tgz \
	    $(call do-log,$(MTD_BDIR)/makepkg.out) && \
	    mv mtd-utils-$(MTD_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;}
	$(Q)rm -rf $(MTD_INSTDIR)
