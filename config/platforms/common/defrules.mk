uboot-loader:
	$(Q)mkdir -p $(UBOOT_BDIR); \
	rm -f $(UBOOT_DIR)/.configured; \
	$(MAKE) -C $(BASEDIR) PLATFORM_CNF=$(BOOT_DEFCONFIG) u-boot-config

linux-config:
	$(Q)mkdir -p $(LINUX_BDIR); \
	rm -f $(LINUX_DIR)/.configured; \
	$(MAKE) -C $(BASEDIR) LINUX_DEFCONF=$(KERNEL_DEFCONFIG) \
	    linux-conf

linux-rebuild:
	$(Q)mkdir -p $(RUNTIME_DIR)
	$(Q)rm -f $(LINUX_DIR)/{.compiled,.rtinstall} && \
	$(MAKE) linux-build
	$(Q)$(MAKE) copy-zimage

copy-zimage: 
	$(Q)mkdir -p $(BOOTIMG_DIR) && \
	for fname in zImage uImage; do \
	$(CP) $(LINUX_BDIR)/arch/$(TARGET_CPU)/boot/$$fname $(BOOTIMG_DIR)/$$fname.bin; \
	done

etc-release:
	$(Q)rm -f $(RUNTIME_DIR)/etc/RELEASE; \
	    touch $(RUNTIME_DIR)/etc/RELEASE
	$(Q)echo -e "OWEN-$(TODAY)-$(BUILD_VERSION)\n"\
	"$(BUILDCONF)" > $(RUNTIME_DIR)/etc/RELEASE

etc-release_akytec:
	$(Q)rm -f $(RUNTIME_DIR)/etc/RELEASE; \
	    touch $(RUNTIME_DIR)/etc/RELEASE
	$(Q)echo -e "akYtec-$(TODAY)-$(BUILD_VERSION)\n"\
	"$(BUILDCONF)" > $(RUNTIME_DIR)/etc/RELEASE


etc-release_som02:
	$(Q)rm -f $(RUNTIME_DIR)/etc/RELEASE.part
	$(Q)rm -f $(RUNTIME_DIR)/etc/RELEASE
	$(Q)touch $(RUNTIME_DIR)/etc/RELEASE.part
	$(Q)touch $(RUNTIME_DIR)/etc/RELEASE 
	$(Q)echo -e "OWEN-$(TODAY)-$(BUILD_VERSION)\n"\
	"$(BUILDCONF)" > $(RUNTIME_DIR)/etc/RELEASE.part

etc-release_evikon:
	$(Q)rm -f $(RUNTIME_DIR)/etc/RELEASE; \
	    touch $(RUNTIME_DIR)/etc/RELEASE
	$(Q)echo -e "Evikon-$(TODAY)-$(BUILD_VERSION)\n"\
	"$(EVICONF)" > $(RUNTIME_DIR)/etc/RELEASE

rootfs-common-files:
	$(Q)tar cp --exclude=.svn -C $(PLATFORMS_DIR)/common/files.ro . | (cd $(RUNTIME_DIR); tar xp); \
		(cd $(PLATFORMS_DIR)/common/files.ro/usr/bin; find ./ -type f | grep -v \.svn) | (cd $(RUNTIME_DIR)/usr/bin; xargs -r chmod +x); \
		(cd $(PLATFORMS_DIR)/common/files.ro/usr/sbin; find ./ -type f | grep -v \.svn) | (cd $(RUNTIME_DIR)/usr/sbin; xargs -r chmod +x); \
		(cd $(PLATFORMS_DIR)/common/files.ro/bin; find ./ -type f | grep -v \.svn) | (cd $(RUNTIME_DIR)/bin; xargs -r chmod +x); \
		(cd $(PLATFORMS_DIR)/common/files.ro/sbin; find ./ -type f | grep -v \.svn) | (cd $(RUNTIME_DIR)/sbin; xargs -r chmod +x); \
		(cd $(PLATFORMS_DIR)/common/files.ro/etc; find ./ -type f -name rc.\* | grep -v \.svn) | (cd $(RUNTIME_DIR)/etc; xargs -r chmod +x); \
		chmod +x $(RUNTIME_DIR)/etc/mdev-usbmodem;\
		chmod +x $(RUNTIME_DIR)/etc/network/udhcpc.sh;\
	    	rm -f $(RUNTIME_DIR)/etc/ppp/ip-down;\
		chmod +x $(RUNTIME_DIR)/etc/ppp/ip-* ;\
		chmod +x $(RUNTIME_DIR)/etc/ppp/gprs_chat.sh;\
		ln -sf /etc/ppp/ip-up $(RUNTIME_DIR)/etc/ppp/ip-down;\
		chmod 0600 $(RUNTIME_DIR)/etc/ppp/{pap,chap}-secrets

userfs-common-files:
	$(Q)tar cp --exclude=.svn -C $(PLATFORMS_DIR)/common/files.rw . | (cd $(USERFS_DIR); tar xp)

common-files: rootfs-common-files userfs-common-files

