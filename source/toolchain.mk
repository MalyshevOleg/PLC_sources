# High level rules to build toolchain
#

TOOLCHAIN_PHOST_INSTALL=$(TOOLCHAIN_DIR)/.toolchain
TOOLCHAIN_HOST_INSTALL=$(TOOLCHAIN_DIR)/.toolchain

BINARCH=$(if $(filter i686,$(subst -, ,$(HOST_CPU))),80386,x86-64)

# Set initail revision number
$(BASEDIR)/version:
	$(Q)touch $@ && echo 000 > $@

PHONY += addons addons-dirclean toolchain toolchain-dirclean
PHONY += toolchain-clean checksystem gcc1 gcc2 gcc3

addons: fakeroot makedevs-native tar pkgtools

addons-dirclean: fakeroot-dirclean makedevs-native-dirclean tar-dirclean

toolchain: $(BASEDIR)/version

ifeq "$(BUILD_CROSS)" "TRUE"

# Build toolchain from the scratch

toolchain: addons gcc3 libtool $(TOOLCHAIN_DIR)/.toolchain

$(TOOLCHAIN_DIR)/.toolchain: $(GCC_DIR)/.gcc3.hostinst $(LIBTOOL_DIR)/.hostinst
	$(Q)(cd $(TARGET_DIR)/$(TARGET)/bin; \
	for p in * ; do \
	    if [ -x $(TARGET_DIR)/bin/$(TARGET)-$$p ] ; then \
		$(SUDO) rm -f $$p; \
		$(SUDO) ln -sf ../../bin/$(TARGET)-$$p $$p; \
	    fi; \
	done;)
	$(Q)(cd $(TARGET_DIR)/bin; \
	    file * | grep -i "$(BINARCH)" | cut -f 1 -d : | \
	    xargs $(SUDO) strip -p --strip-unneeded 2> /dev/null)
	$(Q)find $(TARGET_DIR)/share/man -name '*.?' | \
	    xargs $(SUDO) gzip -9f && \
	find $(TARGET_DIR)/share/info -name '*.info*' \
	    ! -name '*.gz' | xargs $(SUDO) gzip -9f
	$(Q)mkdir -p $(TOOLCHAIN_DIR) && touch $@

else

# Use prebuild toolchain

toolchain: $(TOOLCHAIN_DIR)/.toolchain

$(TOOLCHAIN_DIR)/.toolchain: $(FAKEROOT_DIR)/.hostinst
	$(Q)mkdir -p $(TOOLCHAIN_DIR) && touch $@

endif

checksystem:
	$(call print-info,Checking host system)
	@$(BASEDIR)/scripts/syscheck.sh $(BASEDIR)

toolchain-dirclean: addons-dirclean gcc3-dirclean \
    $(LIBC_NAME)-dirclean linux-dirclean \
    binutils-dirclean libtool-dirclean

toolchain-clean: gcc-clean $(LIBC_NAME)-clean linux-clean binutils-clean \
    libtool-clean

$(LIBC_NAME)2: gcc-stage2 $(LIBC_NAME)-stage2
$(LIBC_NAME)1: gcc-stage1 $(LIBC_NAME)-stage1

gcc3: gcc-stage2 $(LIBC_NAME)-stage2 gcc-stage3
gcc2: gcc-stage1 $(LIBC_NAME)-stage1 gcc-stage2
gcc1: binutils linux-headers gcc-stage1
