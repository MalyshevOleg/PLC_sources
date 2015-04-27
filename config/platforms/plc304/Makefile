# Get settings
#
include $(PLATFORMS_DIR)/$(BUILDCONF)/config.mk

# Common targets and rules
#
include $(PLATFORMS_DIR)/common/defrules.mk

PACK_LIST = \
	$(LIBC_NAME)   \
	busybox        \
	dropbear       \
	zlib           \
	ppp            \
	pptp           \
	mtd-utils      \
	openssl        \
	picocom        \
	inadyn         \
	thttpd         \
	romboot        \
	u-boot         \
	retain         \
	plchal         \
	webconfig      \
        iproute2         \
	iptables	\
	libusbx		\
	usb-modeswitch	\
	comgt		\
	dnsmasq		\
	whatmask	\
	libmnl		\
	strace

# install targets for packages
PACK2INSTALL = $(addsuffix -inst,$(PACK_LIST))

# install step markers
MARK2DELETE = $(foreach item,$(addsuffix _rt_install,$(PACK_LIST)),$($(item)))

# items, that moved from runtime to userfs
UFS_ITEMS = lib/modules

base-system:
	@echo "[`date +"%F %T"`] == checking for toolchain =="
	$(Q)$(MAKE) -s -C $(BASEDIR) toolchain
	@echo "[`date +"%F %T"`] == building packages =="
# do rebuild bootloaders and webconfig
	$(Q)$(MAKE) uboot-loader
	$(Q)rm -f $(ROMBOOT_DIR)/.configured $(WEBCONFIG_DIR)/.configured
	$(Q)$(MAKE) -s -C $(BASEDIR) $(PACK_LIST)
	@echo "[`date +"%F %T"`] == preparing rootfs =="
	$(Q)$(MAKE) -s clean-install
	$(Q)$(call do-fakeroot-save,$(MAKE) rootfs)
# configure, build and install linux kernel
	$(Q)$(MAKE) linux-config
	$(Q)$(MAKE) linux-rebuild
	$(Q)$(call do-fakeroot-inst,$(MAKE) linux-inst)
# install packages
	$(Q)$(call do-fakeroot-inst,$(MAKE) do-install)
	$(Q)$(call do-fakeroot-inst,$(MAKE) devs)
	$(Q)$(call do-fakeroot-inst,$(MAKE) ufs-move)
	@echo "[`date +"%F %T"`] == done. run make tarimg or fsimg =="

do-install:
	@echo "[`date +"%F %T"`] == installing packages for runtime =="
	$(Q)$(MAKE) $(PACK2INSTALL); \
	$(CP) $(TARGET_DIR)/$(TARGET)/lib/libstdc++.so* $(RUNTIME_DIR)/lib/; \
	$(CP) $(PLATFORMS_DIR)/common/files_at91.3.5.3.40/codesyssp35_no_qt_lin3 \
	    $(RUNTIME_DIR)/usr/bin/codesyssp; \
	chmod +x $(RUNTIME_DIR)/usr/bin/codesyssp; \
	chmod +x $(RUNTIME_DIR)/sbin/ferase

clean-install:
	$(Q)rm -f $(LINUX_DIR)/.rtinstall $(MARK2DELETE)
	$(Q)rm -rf $(RUNTIME_DIR) $(USERFS_DIR)
	$(Q)rm -f $(FAKEROOT_FILE)

rootfs:
	$(Q)$(MAKE) rootfs-dirs
	$(Q)$(MAKE) userfs-dirs
	$(Q)$(MAKE) common-files
	$(Q)$(MAKE) etc-files

etc-files:
	$(Q)$(MAKE) etc-fstab etc-hosts etc-inittab etc-ldso \
	    etc-hwclock etc-hostname etc-rcs etc-ufs \
	    etc-release

ROOTFS_DIRLIST = bin dev etc lib mnt/ufs proc sbin sys tmp usr var mnt/etcro mnt/etcrw
USERFS_DIRLIST = etc home root lib/modules usr/bin

rootfs-dirs:
	$(foreach item,$(addprefix $(RUNTIME_DIR)/,$(ROOTFS_DIRLIST)), \
	    $(shell mkdir -p $(item)))
	$(Q)ln -s /mnt/ufs/home $(RUNTIME_DIR)/home
	$(Q)ln -s /mnt/ufs/root $(RUNTIME_DIR)/root
	$(Q)ln -s /mnt/ufs/usr $(RUNTIME_DIR)/usr/local

userfs-dirs:
	$(foreach item,$(addprefix $(USERFS_DIR)/,$(USERFS_DIRLIST)), \
	    $(shell mkdir -p $(item)))
	$(Q)mkdir -p $(USERFS_DIR)/usr/lib $(USERFS_DIR)/usr/sbin \
	    $(USERFS_DIR)/root/retain

devs:
	$(Q)$(TARGET_DIR)/bin/makedevs -d \
	    $(PLATFORMS_DIR)/common/device_table $(RUNTIME_DIR) > /dev/null

etc-fstab:
	$(Q)rm -f $(RUNTIME_DIR)/etc/fstab; touch $(RUNTIME_DIR)/etc/fstab
	$(Q)echo -e \
	"LABEL=/	/             $(ROOTFS_TYPE)	defaults,ro	1 1\n"\
	"none		/proc         proc	defaults	0 0\n"\
	"none		/var          tmpfs	defaults	0 0\n"\
	"none		/dev/pts      devpts	defaults	0 0\n"\
	"none		/dev/shm      tmpfs	defaults	0 0\n"\
	"none		/proc/bus/usb usbfs	defaults	0 0\n"\
	"sysfs		/sys	      sysfs	defaults	0 0\n"\
	"/dev/sda1	/mnt/sda1     auto	defaults	0 0\n"\
	"/dev/sdb1	/mnt/sdb1     auto	defaults	0 0"\
	> $(RUNTIME_DIR)/etc/fstab

etc-hostname:
	$(Q)rm -f $(RUNTIME_DIR)/etc/HOSTNAME
	$(Q)echo "$(TARG_HOSTNAME)" > $(RUNTIME_DIR)/etc/HOSTNAME

etc-hosts:
	$(Q)rm -f $(RUNTIME_DIR)/etc/hosts
	$(Q)echo -e "127.0.0.1	localhost localhost.localdomain \
	    $(TARG_HOSTNAME)" > $(RUNTIME_DIR)/etc/hosts

etc-inittab:
	$(Q)rm -f $(RUNTIME_DIR)/etc/inittab
	$(Q)echo -e \
	"::sysinit:/etc/rc.sysinit\n"\
	"::ctrlaltdel:/sbin/reboot\n"\
	"::shutdown:/etc/rc.final\n"\
	"::restart:/sbin/init"\
	> $(RUNTIME_DIR)/etc/inittab_nc
	$(Q)cp $(RUNTIME_DIR)/etc/inittab_nc $(RUNTIME_DIR)/etc/inittab
	$(Q)echo -e \
	"$(UART_DEV)::respawn:/sbin/getty $(UART_BAUD) $(UART_DEV)"\
	>> $(RUNTIME_DIR)/etc/inittab

etc-hwclock:
	$(Q)rm -f $(RUNTIME_DIR)/etc/hwclock
	$(Q)echo "localtime" > $(RUNTIME_DIR)/etc/hwclock

etc-ldso:
	$(Q)rm -f $(RUNTIME_DIR)/etc/ld.so.conf
	$(Q)echo "/usr/lib" > $(RUNTIME_DIR)/etc/ld.so.conf

etc-rcs:
	$(Q)tar cp --exclude=.svn -C $(PLATFORMS_DIR)/$(BUILDCONF)/files . | \
		(cd $(RUNTIME_DIR); tar xp); \
	    rm -f $(RUNTIME_DIR)/etc/alsa-defaults; \
	    rm -f $(RUNTIME_DIR)/etc/kbd.xml; \
	    rm -f $(RUNTIME_DIR)/etc/rc.sound; \
	    chmod +x $(RUNTIME_DIR)/etc/rc.*
	$(Q)sed -i 's,ubi1:ufs,ubi0:ufs,g' $(RUNTIME_DIR)/etc/rc.fs

etc-ufs:
	$(Q)tar cp --exclude=.svn -C $(PLATFORMS_DIR)/$(BUILDCONF)/ufiles . | \
		(cd $(USERFS_DIR); tar xp); \
	    chmod +x $(USERFS_DIR)/root/make_id.sh;\
	    chmod +x $(USERFS_DIR)/root/write_id.sh;\
	    $(SED) -i -e '/PLC_ID=/s/=0x.*/=$(RETAIN_PLC_ID)/' \
		    $(USERFS_DIR)/root/make_id.sh

ufs-move:
	$(Q)$(call rfs-to-ufs)
	$(Q)(cd $(RUNTIME_DIR)/lib/gconv; ls | egrep -v "CP1251.so|INIS-CYRILLIC.so|ISO8859-5.so|KOI8-R.so|KOI8-RU.so|UNICODE.so|UTF-7.so|UTF-16.so|UTF-32.so|gconv-modules" | xargs rm)
	$(Q)rm -f $(USERFS_DIR)/lib/modules/*/build $(USERFS_DIR)/lib/modules/*/source
	$(Q)mv $(RUNTIME_DIR)/usr/bin/rmsync $(USERFS_DIR)/root/retain/rmsync && \
	mv $(RUNTIME_DIR)/usr/bin/rmsync.cfg.in $(USERFS_DIR)/root/retain/rmsync.cfg.in && \
	$(SED) -i -e '/eeprom/s/^RETAIN_FILE/#RETAIN_FILE/;/bin/s/^#RETAIN_FILE/RETAIN_FILE/' \
	    $(USERFS_DIR)/root/retain/rmsync.cfg.in && \
	rm -rf $(USERFS_DIR)/root/www && \
	mv $(RUNTIME_DIR)/www $(USERFS_DIR)/root/www && \
	rm -f $(USERFS_DIR)/root/CoDeSysSP/codesyssp && \
	ln -s /usr/bin/codesyssp $(USERFS_DIR)/root/CoDeSysSP/codesyssp && \
	cat $(PLATFORMS_DIR)/common/files/visu.tar | \
	    (cd $(USERFS_DIR)/root/CoDeSysSP; tar xp)
	$(Q){ echo -e "#mtd dev\t#offset\t#envsz\t#erase sz" > $(RUNTIME_DIR)/etc/fw_env.config; \
	      echo "$(MTD_PARTS)" | \cut -d: -f2 | \tr  ',' '\n' | \egrep 'env|u-boot-env' -n | \cut -d: -f1 | \xargs -I% sh -c 'echo -n /dev/mtd$$((%-1))' >> $(RUNTIME_DIR)/etc/fw_env.config; \
	      echo -e "\t0x0000\t$(UBOOT_ENV_SIZE)\t0x20000" >> $(RUNTIME_DIR)/etc/fw_env.config; }
	$(Q)cp -rp $(RUNTIME_DIR)/etc/* $(RUNTIME_DIR)/mnt/etcro

jfsimg:
	$(Q)$(call do-fakeroot-inst,$(MAKE) imgprep)

imgprep:
	$(Q){ cd $(BOOTSYS_DIR); $(TARGET_DIR)/bin/mkfs.ubifs -r userfs -o user.fs -m 8 -e 130944 -c 60 --compr=zlib; }

cramfsimg fsimg:
	$(Q)$(call do-fakeroot-inst,$(MAKE) imgprep)
	$(Q)$(call do-fakeroot-inst,$(MAKE) cramprep)
	$(Q)$(BASEDIR)/scripts/make_off_script.sh $(FLASH_TYPE) $(FLASH_SIZE) \
	    "$(BOOT_ARGS)" $(MTD_PARTS_SHIFT) $(MACH) $(BOOTSYS_DIR)/boot \
	    $(TARGET_DIR)/bin > /dev/null
	$(Q){ cd $(BOOTSYS_DIR); \
		$(BASEDIR)/scripts/mkfw.sh plc304u.bin at91-nor u-boot "$(UBOOT_BOARD_NAME)" "$(UBOOT_BOARD_FULL_NAME)" "$(BOOT_ARGS)" $(shell printf "%u.%03u" `expr $(BUILD_VERSION) / 1000` `expr $(BUILD_VERSION) % 1000`) $(FLASH_BASE) $(FLASH_SIZE) $(FLASH_ERASE_SIZE); \
		$(BASEDIR)/scripts/mkfw.sh plc304f.bin at91-nor full "$(UBOOT_BOARD_NAME)" "$(UBOOT_BOARD_FULL_NAME)" "$(BOOT_ARGS)" $(shell printf "%u.%03u" `expr $(BUILD_VERSION) / 1000` `expr $(BUILD_VERSION) % 1000`) $(FLASH_BASE) $(FLASH_SIZE) $(FLASH_ERASE_SIZE); }

cramprep:
	$(Q)mksquashfs $(BOOTSYS_DIR)/runtime/ $(BOOTSYS_DIR)/plc.fs -b 131072 -comp xz -no-progress -noappend >/dev/null

tarimg:
	$(Q)$(call do-fakeroot-inst,$(MAKE) tarprep)

tarprep:
	$(Q){ cd $(BOOTSYS_DIR); \
	    $(TAR) $(TAR_OPTS) runtime.tar runtime; \
	    $(TAR) $(TAR_OPTS) ufs.tar userfs; }
