# Package: TZDATA
TZDATA_VERS = 2012d
TZDATA_EXT  = tar.gz
TZDATA_SITE = http://www.iana.org/time-zones/repository/releases
TZDATA_PDIR = pkgs/tzdata

TZDATA_FILES = tzcode2012c.tar.gz

TZDATA_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH \
    CFLAGS="-Os" CC=$(TARGET)-gcc
TZDATA_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr

TZDATA_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH
TZDATA_MAKE_TARGS = SRCDIR=$(TZDATA_SDIR)

TZDATA_RUNTIME_INSTALL = y
TZDATA_DEPS = TOOLCHAIN

TZDATA_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) tzdata-rt) \
    $(call autoclean,tzdata-dirclean)

$(eval $(call create-common-vars,tzdata,TZDATA,-))
TZDATA_SRC = tzdata$(TZDATA_VERS).$(TZDATA_EXT)
TZDATA_SDIR = $(PKGSOURCE_DIR)/tzdata$(TZDATA_VERS)
TZDATA_STEPS_DIR = $(PKGSTEPS_DIR)/tzdata$(TZDATA_VERS)
TZDATA_DIR = $(PKGBUILD_DIR)/tzdata$(TZDATA_VERS)
TZDATA_DL_DIR = $(DOWNLOAD_DIR)/tzdata$(TZDATA_VERS)
$(eval $(call create-common-targs,tzdata,TZDATA,-))
$(eval $(call create-install-targs,tzdata,TZDATA,-))

$(TZDATA_STEPS_DIR)/.unpacked: $(TZDATA_STEPS_DIR)/.dirprep
	$(call print-info,[UNPAC] TZDATA $(TZDATA_VERS))
	$(Q)mkdir -p $(TZDATA_SDIR)
	$(Q)$(INFLATE$(suffix $(TZDATA_EXT))) $(TZDATA_SOURCE_TARGET) | \
	    $(TAR) -C $(TZDATA_SDIR) $(UNTAR_OPTS) -
	$(Q)$(foreach file,$(TZDATA_FILES), \
	    $(INFLATE$(suffix $(TZDATA_EXT))) \
	    $(addprefix $(TZDATA_DL_DIR)/,$(file)) | \
	    $(TAR) -C $(TZDATA_SDIR) $(UNTAR_OPTS) - )
	$(Q)touch $@

$(TZDATA_DIR)/.configured: $(TZDATA_STEPS_DIR)/.patched
	$(call print-info,[CONFG] TZDATA $(TZDATA_VERS))
	$(Q)mkdir -p $(TZDATA_BDIR) && \
	    ln -sf $(TZDATA_SDIR)/Makefile $(TZDATA_BDIR)/Makefile && \
	    $(CP) $(TZDATA_SDIR)/tzselect.ksh $(TZDATA_BDIR)/ && \
	    $(CP) $(TZDATA_SDIR)/leapseconds $(TZDATA_BDIR)/
	$(Q)touch $@

$(TZDATA_DIR)/.hostinst: $(TZDATA_DIR)/.built
	$(Q)touch $@

tzdata-rt:
	$(Q){ rm -rf $(TZDATA_INSTDIR) && \
	mkdir -p $(TZDATA_INSTDIR)/usr && \
	    $(MAKE) -C $(TZDATA_BDIR) TOPDIR=$(TZDATA_INSTDIR)/usr \
	    SRCDIR=$(TZDATA_SDIR) install \
	    $(call do-log,$(TZDATA_BDIR)/posthostinst.out); }
	$(Q)(cd $(TZDATA_INSTDIR); \
	    rm -rf usr/lib; mv usr/etc . ; \
	    rm -f usr/share/zoneinfo/localtime; \
	    ln -s /etc/localtime usr/share/zoneinfo/localtime; \
	    cp usr/share/zoneinfo/Europe/Moscow etc/localtime; \
	    echo "Europe/Moscow" > etc/timezone; \
	    chmod 664 etc/localtime etc/timezone; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) tzdata$(TZDATA_VERS).tgz \
		$(call do-log,$(TZDATA_BDIR)/makepkg.out) && \
	    mv tzdata$(TZDATA_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(TZDATA_INSTDIR)
