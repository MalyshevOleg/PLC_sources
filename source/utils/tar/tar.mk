# Package: TAR
TAR_VERS = 1.13
TAR_EXT  = tar.gz
TAR_SITE = http://ftp.gnu.org/gnu/tar
TAR_PDIR = utils/tar

TAR_CONFIG_VARS = CFLAGS=-O2

TAR_CONFIG_OPTS = \
    --prefix=$(TARGET_DIR) \
    --infodir=$(TARGET_DIR)/share/info \
    --mandir=$(TARGET_DIR)/share/man \
    --disable-nls \
    --host=$(HOST_CPU)

TAR_POSTHOSTINST = \
    $(SUDO) mv $(TARGET_DIR)/bin/tar $(TARGET_DIR)/bin/tar-1.13 && \
    find $(TARGET_DIR)/share/info -name 'tar.info*' \
        ! -name '*.gz' | xargs $(SUDO) gzip -9f \
    $(call autoclean,tar-dirclean)

TAR_INSTALL = $(SUDO)

$(eval $(call create-common-defs,tar,TAR,-))

# Redefine
TAR_INSTALL_TARGET = install-strip

$(TAR_STEPS_DIR)/.patched: $(TAR_STEPS_DIR)/.unpacked
	$(call print-info,[PATCH] TAR $(TAR_VERS))
	$(Q)mkdir -p $(TAR_BDIR) && scripts/patch-kernel.sh \
	    $(TAR_SDIR) $(TAR_PATCH_DIR)/ \*.{patch,gz} \
	    $(call do-log,$(TAR_BDIR)/patch.out) && \
	chmod 664 $(TAR_SDIR)/config.{guess,sub} && \
	cp -L $(VERBOSE_COPY) /usr/share/libtool/config/config.* $(TAR_SDIR)
	$(Q)touch $@
