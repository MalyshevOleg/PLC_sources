# Package: GCC
GCC_VERS = 4.3.2
GCC_EXT  = tar.bz2
GCC_SITE = http://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERS)
GCC_PDIR = toolchain/gcc

$(eval $(call create-common-defs,gcc,GCC,-))

GCC_BDIR1 = $(GCC_DIR)/build1
GCC_BDIR2 = $(GCC_DIR)/build2

# GCC stage1 - build the static core gcc without libgcc
#

GCC1_OPTS = --without-headers

ifeq ($(findstring x4.,x$(GCC_VERS)),x4.)
GCC1_OPTS:=--disable-libmudflap
GCC1_OPTS+=--with-newlib
else
GCC1_OPTS:=
endif

ifeq "$(MACH)" "at91"
SOFT_FLOAT=--with-float=soft
ARCH_VAL="armv4t"
else ifeq "$(MACH)" "s3c"
SOFT_FLOAT=--with-float=soft
ARCH_VAL="armv4t"
else ifeq "$(MACH)" "s3c2410"
SOFT_FLOAT=--with-float=soft
else ifeq "$(MACH)" "qemu"
SOFT_FLOAT=--with-float=soft
ARCH_VAL="armv4t"
else
SOFT_FLOAT=--with-fp=vfp
SOFT_FLOAT+=--with-float=softfp
ARCH_VAL="armv7-a"
endif

$(GCC_DIR)/.gcc1.configured: $(GCC_STEPS_DIR)/.patched
	$(call print-info,[CONFG] GCC $(GCC_VERS) stage1)
	$(Q)rm -rf $(GCC_BDIR1) && mkdir -p $(GCC_BDIR1) && cd $(GCC_BDIR1) && \
	PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-O2" \
	    $(GCC_SDIR)/$(CONFIGURE) \
	    --build=$(HOST_CPU) \
	    --target=$(TARGET) \
	    --prefix=$(TARGET_DIR) \
	    --with-local-prefix=$(TARGET_DIR)/$(TARGET) \
	    --infodir=$(TARGET_DIR)/share/info \
	    --mandir=$(TARGET_DIR)/share/man \
	    --enable-languages=c \
	    --enable-symvers=gnu \
	    --enable-target-optspace \
	    $(GCC1_OPTS) \
	    $(SOFT_FLOAT) \
	    --disable-shared \
	    --disable-threads \
	    --disable-multilib \
	    MAKEINFO=missing \
	    --disable-nls $(call do-log,$(GCC_BDIR1)/configure.out)
	$(Q)touch $@

$(GCC_DIR)/.gcc1.configured: $(BINUTILS_DIR)/.hostinst 
$(GCC_DIR)/.gcc1.configured: $(TOOLCHAIN_DIR)/.headers

$(GCC_DIR)/.gcc1.built: $(GCC_DIR)/.gcc1.configured
	$(call print-info,[BUILD] GCC $(GCC_VERS) stage1)
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(GCC_BDIR1) all-gcc \
	    $(call do-log,$(GCC_BDIR1)/make.out)
	$(Q)touch $@

$(GCC_DIR)/.gcc1.hostinst: $(GCC_DIR)/.gcc1.built
	$(call print-info,[INSTL] GCC $(GCC_VERS) stage1 to host)
	$(Q)$(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH) \
	    $(MAKE) -C $(GCC_BDIR1) install-gcc \
	    $(call do-log,$(GCC_BDIR1)/hostinst.out)
	$(Q)touch $@

# GCC stage2 - build the shared core gcc with libgcc
#

$(GCC_DIR)/.gcc2.configured: $(TOOLCHAIN_DIR)/.$(LIBC_NAME)1
	$(call print-info,[CONFG] GCC $(GCC_VERS) stage2)
	$(Q)rm -rf $(GCC_BDIR2) && mkdir -p $(GCC_BDIR2) && cd $(GCC_BDIR2) && \
	PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-O2" \
	    $(GCC_SDIR)/$(CONFIGURE) \
	    --build=$(HOST_CPU) \
	    --target=$(TARGET) \
	    --prefix=$(TARGET_DIR) \
	    --with-local-prefix=$(TARGET_DIR)/$(TARGET) \
	    --infodir=$(TARGET_DIR)/share/info \
	    --mandir=$(TARGET_DIR)/share/man \
	    --with-arch=$(ARCH_VAL) \
	    --enable-languages=c \
	    --enable-symvers=gnu \
	    --enable-target-optspace \
	    --enable-shared \
	    --enable-__cxa_atexit \
	    --enable-threads=posix \
	    --without-headers \
	    $(SOFT_FLOAT) \
	    --disable-libmudflap \
	    --disable-multilib \
	    --disable-nls $(call do-log,$(GCC_BDIR2)/configure.out)
	$(Q)touch $@

$(GCC_DIR)/.gcc2.built: $(GCC_DIR)/.gcc2.configured
	$(call print-info,[BUILD] GCC $(GCC_VERS) stage2)
	$(Q)PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(GCC_BDIR2) all-gcc all-target-libgcc \
	    $(call do-log,$(GCC_BDIR2)/make.out)
	$(Q)touch $@

$(GCC_DIR)/.gcc2.hostinst: $(GCC_DIR)/.gcc2.built
	$(call print-info,[INSTL] GCC $(GCC_VERS) stage2 to host)
	$(Q)$(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH) \
	    $(MAKE) -C $(GCC_BDIR2) install-gcc install-target-libgcc \
	    $(call do-log,$(GCC_BDIR2)/hostinst.out)
	$(Q)touch $@

# GCC stage3 - build the final gcc
#

$(GCC_DIR)/.gcc3.configured: $(TOOLCHAIN_DIR)/.$(LIBC_NAME)2
	$(call print-info,[CONFG] GCC $(GCC_VERS) stage3)
	$(Q)mkdir -p $(GCC_BDIR) && cd $(GCC_BDIR) && \
	PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-O2" \
	    $(GCC_SDIR)/$(CONFIGURE) \
	    --build=$(HOST_CPU) \
	    --host=$(HOST_CPU) \
	    --target=$(TARGET) \
	    --prefix=$(TARGET_DIR) \
	    --infodir=$(TARGET_DIR)/share/info \
	    --mandir=$(TARGET_DIR)/share/man \
	    --with-headers \
	    --with-local-prefix=$(TARGET_DIR)/$(TARGET) \
	    --with-arch=$(ARCH_VAL) \
	    --enable-languages=c,c++ \
	    --enable-symvers=gnu \
	    --enable-target-optspace \
	    --enable-shared \
	    --enable-__cxa_atexit \
	    --enable-threads=posix \
	    --enable-c99 \
	    --enable-long-long \
	    $(SOFT_FLOAT) \
	    --disable-libgomp \
	    --disable-multilib \
	    --disable-nls $(call do-log,$(GCC_BDIR)/configure.out)
	$(Q)touch $@

# we use sys-include to get proper limits.h
$(GCC_DIR)/.gcc3.built: $(GCC_DIR)/.gcc3.configured
	$(call print-info,[BUILD] GCC $(GCC_VERS) stage3)
	$(Q)$(SUDO) ln -sf $(TARGET_DIR)/$(TARGET)/include \
	    $(TARGET_DIR)/$(TARGET)/sys-include && \
	PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKE) -C $(GCC_BDIR) $(call do-log,$(GCC_BDIR)/make.out) && \
	$(SUDO) rm $(TARGET_DIR)/$(TARGET)/sys-include
	$(Q)touch $@

$(GCC_DIR)/.gcc3.hostinst: $(GCC_DIR)/.gcc3.built
	$(call print-info,[INSTL] GCC $(GCC_VERS) stage3 to host)
	$(Q)$(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH) \
	    $(MAKE) -C $(GCC_BDIR) install \
	    $(call do-log,$(GCC_BDIR)/hostinst.out)
	$(Q)touch $@

PHONY += gcc-stage1 gcc-stage2 gcc-stage3

gcc-stage3: $(GCC_DIR)/.gcc3.hostinst
gcc-stage2: $(GCC_DIR)/.gcc2.hostinst
gcc-stage1: $(GCC_DIR)/.gcc1.hostinst
