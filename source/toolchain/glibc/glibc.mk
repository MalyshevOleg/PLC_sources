# Package: GLIBC
GLIBC_VERS = 2.7
GLIBC_EXT  = tar.bz2
GLIBC_SITE = ftp://ftp.gnu.org/pub/gnu/glibc
GLIBC_PDIR = toolchain/glibc

GLIBC_ADDONS = ports
ifeq "$(GLIBC_VERS)" "2.7"
GLIBC_ADDONS+=libidn
endif
GLIBC_FILES = $(addprefix glibc-,$(addsuffix -$(GLIBC_VERS).$(GLIBC_EXT),$(GLIBC_ADDONS)))

GLIBC_INSTALL = $(SUDO)
GLIBC_RUNTIME_INSTALL = y

$(eval $(call create-common-defs,glibc,GLIBC,-))

ifeq "$(MACH)" "s3c"
ARCH_CFLAGS=-march=armv4t -O2
RUNT_CMD = rm -rf sbin
else ifeq "$(MACH)" "qemu"
ARCH_CFLAGS=-march=armv4t -O2
RUNT_CMD = rm -rf sbin
else ifeq "$(MACH)" "at91"
ARCH_CFLAGS=-march=armv4t -O2
RUNT_CMD = rm -rf sbin
else
ARCH_CFLAGS=-O3 -march=armv7-a -mtune=cortex-a8 -mfpu=neon -mfloat-abi=softfp
RUNT_CMD = rm `find sbin -type f -a ! -name ldconfig`
endif

$(GLIBC_STEPS_DIR)/.addunpack: $(GLIBC_STEPS_DIR)/.unpacked
	$(call print-info,[UNPAC] GLIBC $(GLIBC_VERS) addons)
	$(Q)$(foreach file,$(GLIBC_FILES), \
	    $(INFLATE$(suffix $(GLIBC_EXT))) \
	    $(addprefix $(GLIBC_DL_DIR)/,$(file)) | \
	    $(TAR) -C $(PKGSOURCE_DIR)/glibc-$(GLIBC_VERS) $(UNTAR_OPTS) - ;)
	$(Q)$(foreach file,$(GLIBC_ADDONS), \
	    mv $(PKGSOURCE_DIR)/glibc-$(GLIBC_VERS)/glibc-$(file)-$(GLIBC_VERS) \
		$(PKGSOURCE_DIR)/glibc-$(GLIBC_VERS)/$(file); )
	$(Q)touch $@

$(GLIBC_STEPS_DIR)/.patched: $(GLIBC_STEPS_DIR)/.addunpack

# GLIBC stage1
#

$(GLIBC_DIR)/.glibc1.configured: $(GLIBC_STEPS_DIR)/.patched $(GCC_DIR)/.gcc1.hostinst
	$(call print-info,[CONFG] GLIBC $(GLIBC_VERS) stage1)
	$(Q)$(SUDO) rm -rf $(GLIBC_BDIR) && mkdir -p $(GLIBC_BDIR) && \
	cd $(GLIBC_BDIR) && PATH=$(TARGET_DIR)/bin:$$PATH \
	CC=$(TARGET)-gcc CFLAGS="$(ARCH_CFLAGS)" \
	libc_cv_forced_unwind=yes \
	libc_cv_c_cleanup=yes \
	    $(GLIBC_SDIR)/$(CONFIGURE) \
	    --build=$(HOST_CPU) \
	    --host=$(TARGET) \
	    --target=$(TARGET) \
	    --prefix= \
	    --enable-add-ons \
	    --enable-kernel=2.6.30 \
	    --enable-hacker-mode \
	    --with-headers=$(TARGET_DIR)/$(TARGET)/include \
	    --without-cvs \
	    --without-gd \
	    --without-nptl \
	    --without-selinux \
	    --disable-sanity-checks \
	    --disable-debug \
	    --disable-profile $(call do-log,$(GLIBC_BDIR)/configure.out)
	$(Q)touch $@

$(GLIBC_DIR)/.glibc1.built: $(GLIBC_DIR)/.glibc1.configured
	$(call print-info,[BUILD] GLIBC $(GLIBC_VERS) stage1)
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(GLIBC_BDIR) csu/subdir_lib \
	    $(call do-log,$(GLIBC_BDIR)/make.out) && \
	    $(SUDO) $(CP) $(GLIBC_BDIR)/csu/crt[1in].o \
		$(TARGET_DIR)/$(TARGET)/lib && \
	$(SUDO) $(TARGET_DIR)/bin/$(TARGET)-gcc -nostdlib -nostartfiles \
	    -shared -x c /dev/null -o $(TARGET_DIR)/$(TARGET)/lib/libc.so
	$(Q)touch $@

$(GLIBC_DIR)/.glibc1.hostinst: $(GLIBC_DIR)/.glibc1.built
	$(call print-info,[INSTL] GLIBC $(GLIBC_VERS) stage1)
	$(Q)echo "install_root=$(TARGET_DIR)/$(TARGET)" > $(GLIBC_BDIR)/configparms
	$(Q)$(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH) \
	    $(MAKE) -C $(GLIBC_BDIR) install-bootstrap-headers=yes \
	    install_root=$(TARGET_DIR)/$(TARGET) \
	    prefix= install-headers \
	    $(call do-log,$(GLIBC_BDIR)/hostinst_headers.out) && \
	(cd $(TARGET_DIR)/$(TARGET) && \
	    $(SUDO) touch include/gnu/stubs.h && \
	    $(SUDO) $(CP) $(GLIBC_BDIR)/bits/stdio_lim.h include/bits/)
	$(Q)touch $@

$(TOOLCHAIN_DIR)/.glibc1: $(GLIBC_DIR)/.glibc1.hostinst
	$(Q)touch $@

# GLIBC stage2
#
$(GLIBC_DIR)/.configured: $(GLIBC_STEPS_DIR)/.patched $(GCC_DIR)/.gcc2.hostinst
	$(call print-info,[CONFG] GLIBC $(GLIBC_VERS) stage2)
	$(Q)$(SUDO) rm -rf $(GLIBC_BDIR) && mkdir -p $(GLIBC_BDIR) && \
	cd $(GLIBC_BDIR) && PATH=$(TARGET_DIR)/bin:$$PATH \
	CC=$(TARGET)-gcc RANLIB=$(TARGET)-ranlib \
	CFLAGS="$(ARCH_CFLAGS)" \
	libc_cv_forced_unwind=yes \
	libc_cv_c_cleanup=yes \
	    $(GLIBC_SDIR)/$(CONFIGURE) \
	    --build=$(HOST_CPU) \
	    --host=$(TARGET) \
	    --target=$(TARGET) \
	    --prefix= \
	    --enable-add-ons=nptl,ports,libidn \
	    --enable-shared \
	    --with-headers=$(TARGET_DIR)/$(TARGET)/include \
	    --with-fp \
	    --with-tls \
	    --with-__thread \
	    --without-cvs \
	    --without-gd \
	    --without-selinux \
	    --disable-debug \
	    --disable-profile $(call do-log,$(GLIBC_BDIR)/configure.out)
	$(Q)touch $@

$(GLIBC_DIR)/.built: $(GLIBC_DIR)/.configured
	$(call print-info,[BUILD] GLIBC $(GLIBC_VERS) stage2)
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(GLIBC_BDIR) $(call do-log,$(GLIBC_BDIR)/make.out)
	$(Q)touch $@

$(GLIBC_DIR)/.hostinst: $(GLIBC_DIR)/.built
	$(call print-info,[INSTL] GLIBC $(GLIBC_VERS) stage2)
	$(Q)echo "install_root=$(TARGET_DIR)/$(TARGET)" > $(GLIBC_BDIR)/configparms
	$(Q)$(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH) \
	    $(MAKE) -C $(GLIBC_BDIR) install \
	    install_root=$(TARGET_DIR)/$(TARGET) \
	    $(call do-log,$(GLIBC_BDIR)/hostinst.out)
	$(Q)( \
	for inf in $(wildcard $(TARGET_DIR)/$(TARGET)/include/rpcsvc/*.x); do \
	    if [ "$$inf" == "*.x" ]; then break; fi && \
	    outf=`echo $$inf | $(SED) -e 's,\.x$$,.h,'` && \
	    if [ ! -f "$$outf" ]; then $(SUDO) rpcgen -h $$inf -o $$outf; fi && \
	    $(SUDO) rm $$inf; \
	done)
	$(Q)(mkdir -p $(BINARIES_DIR)/arm$(MACH)-runtime/{bin,sbin} && \
	    $(SUDO) $(CP) $(TARGET_DIR)/$(TARGET)/bin/{gencat,getconf,getent,iconv,locale,localedef,rpcgen,sprof,pcprofiledump} \
		$(BINARIES_DIR)/arm$(MACH)-runtime/bin/ ; \
	    $(SUDO) $(CP) $(TARGET_DIR)/$(TARGET)/sbin/* \
		$(BINARIES_DIR)/arm$(MACH)-runtime/sbin/ ; \
	    $(SUDO) rm -f $(TARGET_DIR)/$(TARGET)/bin/{gencat,getconf,getent,iconv,locale,localedef,rpcgen,sprof,pcprofiledump} ; \
	    $(SUDO) rm -rf $(TARGET_DIR)/$(TARGET)/sbin)
	$(Q)touch $@

$(TOOLCHAIN_DIR)/.glibc2: $(GLIBC_DIR)/.hostinst
	$(Q)touch $@

$(GLIBC_DIR)/.posthostinst: $(GLIBC_DIR)/.hostinst
	$(Q)$(call do-fakeroot,$(MAKE) glibc-rt)
	$(Q)touch $@

glibc-rt:
# build the runtime package
	$(Q){ rm -rf $(GLIBC_INSTDIR) && mkdir -p $(GLIBC_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(GLIBC_BDIR) install \
	    install_root=$(GLIBC_INSTDIR) \
	    $(call do-log,$(GLIBC_BDIR)/posthostinst.out); }
	$(Q)(cd $(GLIBC_INSTDIR); \
	    rm -rf share include libexec/getconf; \
	    rm lib/*.a lib/*.o; \
	    rm `find bin -type f -a ! -name ldd`; \
	    $(RUNT_CMD);)
	$(Q)$(CP) $(TARGET_DIR)/$(TARGET)/lib/libgcc_s.so* \
	    $(GLIBC_INSTDIR)/lib/
	$(Q)(cd $(GLIBC_INSTDIR); \
	    file lib/* | grep "shared object" | cut -f 1 -d : | \
	    xargs $(TARGET_DIR)/bin/$(TARGET)-strip --strip-all ; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip sbin/* 2> /dev/null ; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(MAKEPKG) glibc-$(GLIBC_VERS).tgz \
		$(call do-log,$(GLIBC_BDIR)/makepkg.out) && \
	    mv glibc-$(GLIBC_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(GLIBC_INSTDIR)

glibc-unpack: $(GLIBC_STEPS_DIR)/.addunpack

PHONY += glibc-stage1 glibc-stage2

glibc-stage2: $(GLIBC_DIR)/.posthostinst
glibc-stage1: $(GLIBC_DIR)/.glibc1.hostinst
