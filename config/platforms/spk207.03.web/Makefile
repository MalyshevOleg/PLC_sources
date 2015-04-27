# Get settings
#
include $(PLATFORMS_DIR)/$(BUILDCONF)/config.mk

# Common targets and rules
#
include $(PLATFORMS_DIR)/common/defrules.mk

PACK_LIST = \
	$(LIBC_NAME)     \
	busybox          \
	dropbear         \
	zlib             \
	ppp              \
	pptp             \
	gfx              \
	fbset            \
	mtd-utils        \
	apcupsd          \
	openssl          \
	picocom          \
	inadyn           \
	thttpd           \
	alsa-lib         \
	ncurses          \
	alsa-utils       \
	tslib            \
	libxml2          \
	glib             \
	libogg           \
	libvorbis        \
	gstreamer        \
	gst-plugins-base \
	qt		 \
        iproute2         \
	iptables	\
	libusbx		\
	usb-modeswitch	\
	comgt		\
	dnsmasq		\
	whatmask	\
	libmnl		\
	fbmode           \
	retain           \
	x-loader         \
	iperf		 \
	ts_press         \
	u-boot           \
	strace

# install targets for packages
PACK2INSTALL = $(addsuffix -inst,$(PACK_LIST))

# install step markers
MARK2DELETE = $(foreach item,$(addsuffix _rt_install,$(PACK_LIST)),$($(item)))

base-system:
	@echo "[`date +"%F %T"`] == checking for toolchain =="
	$(Q)$(MAKE) -s -C $(BASEDIR) toolchain
	@echo "[`date +"%F %T"`] == building packages =="
# do rebuild bootloaders
	$(Q)$(MAKE) uboot-loader
	$(Q)rm -f $(XLOADER_DIR)/.configured
	$(Q)$(MAKE) -s -C $(BASEDIR) $(PACK_LIST)
	@echo "[`date +"%F %T"`] == preparing rootfs =="
	$(Q)$(MAKE) -s clean-install
	$(Q)$(call do-fakeroot-save,$(MAKE) rootfs)
# configure, build and install linux kernel & external modules
	$(Q)$(MAKE) linux-config
	$(Q)$(MAKE) linux-rebuild
	$(Q)$(call do-fakeroot-inst,$(MAKE) linux-inst)
	$(Q)$(MAKE) ipset ipset-inst
	$(Q)$(MAKE) gfxkm
# install packages
	$(Q)$(call do-fakeroot-inst,$(MAKE) do-install)
	$(Q)$(call do-fakeroot-inst,$(MAKE) devs)
	$(Q)$(call do-fakeroot-inst,$(MAKE) ufs-move)
	$(Q)rm -f $(RUNTIME_DIR)/lib/libQtWebKit.so*
	$(Q)rm -f $(RUNTIME_DIR)/lib/libvorbis*.so*
	@echo "[`date +"%F %T"`] == done. run make tarimg or fsimg =="

do-install:
	@echo "[`date +"%F %T"`] == installing packages for runtime =="
	$(Q)$(MAKE) $(PACK2INSTALL); \
	$(CP) $(TARGET_DIR)/$(TARGET)/lib/libstdc++.so* $(RUNTIME_DIR)/lib/; \
	$(CP) $(PLATFORMS_DIR)/common/files_am35.3.5.4.4/codesyssp35_lin \
	    $(RUNTIME_DIR)/usr/bin/codesyssp; \
	chmod +x $(RUNTIME_DIR)/usr/bin/codesyssp; \
	chmod +x $(RUNTIME_DIR)/usr/bin/bootmode

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

ROOTFS_DIRLIST = bin dev etc lib mnt/ufs mnt/etcro mnt/etcrw proc \
    sbin sys tmp usr/bin var
USERFS_DIRLIST = lib/modules root root/retain usr

rootfs-dirs:
	$(foreach item,$(addprefix $(RUNTIME_DIR)/,$(ROOTFS_DIRLIST)), \
	    $(shell mkdir -p $(item)))
	$(Q)ln -s /mnt/ufs/home $(RUNTIME_DIR)/home
	$(Q)ln -s /mnt/ufs/root $(RUNTIME_DIR)/root
	$(Q)ln -s /mnt/ufs/usr $(RUNTIME_DIR)/usr/local

userfs-dirs:
	$(foreach item,$(addprefix $(USERFS_DIR)/,$(USERFS_DIRLIST)), \
	    $(shell mkdir -p $(item)))
	$(Q)mkdir -p $(USERFS_DIR)/usr/lib $(USERFS_DIR)/usr/sbin

devs:
	$(Q)$(TARGET_DIR)/bin/makedevs -d \
	    $(PLATFORMS_DIR)/common/device_table $(RUNTIME_DIR) > /dev/null && \
	    if [ -f $(PLATFORMS_DIR)/$(BUILDCONF)/device_table ] ; then \
		$(TARGET_DIR)/bin/makedevs -d \
		    $(PLATFORMS_DIR)/$(BUILDCONF)/device_table $(RUNTIME_DIR) > /dev/null ; \
	    fi

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
	$(Q)touch $(RUNTIME_DIR)/etc/HOSTNAME && \
	echo "$(TARG_HOSTNAME)" > $(RUNTIME_DIR)/etc/HOSTNAME

etc-hosts:
	$(Q)touch $(RUNTIME_DIR)/etc/hosts && \
	echo -e "127.0.0.1	localhost localhost.localdomain \
	    $(TARG_HOSTNAME)" > $(RUNTIME_DIR)/etc/hosts

etc-inittab:
	$(Q)touch $(RUNTIME_DIR)/etc/inittab && \
	echo -e \
	"::sysinit:/etc/rc.sysinit\n"\
	"::ctrlaltdel:/sbin/reboot\n"\
	"::shutdown:/etc/rc.final\n"\
	"::restart:/sbin/init\n"\
	"$(UART_DEV)::respawn:/sbin/getty $(UART_BAUD) $(UART_DEV)"\
	> $(RUNTIME_DIR)/etc/inittab

etc-hwclock:
	$(Q)touch $(RUNTIME_DIR)/etc/hwclock && \
	echo "localtime" > $(RUNTIME_DIR)/etc/hwclock

etc-ldso:
	$(Q)touch $(RUNTIME_DIR)/etc/ld.so.conf && \
	echo "/usr/lib" > $(RUNTIME_DIR)/etc/ld.so.conf

etc-rcs:
	$(Q)tar cp --exclude=.svn -C $(PLATFORMS_DIR)/$(BUILDCONF)/files . | \
		(cd $(RUNTIME_DIR); tar xp); \
	    chmod +x $(RUNTIME_DIR)/etc/rc.*

etc-ufs:
	$(Q)tar cp --exclude=.svn -C $(PLATFORMS_DIR)/$(BUILDCONF)/ufiles . | \
		(cd $(USERFS_DIR); tar xp)

ufs-move:
	$(Q)rm -rf $(USERFS_DIR)/lib/modules && \
	mv $(RUNTIME_DIR)/lib/modules $(USERFS_DIR)/lib/ && \
	ln -s /mnt/ufs/lib/modules $(RUNTIME_DIR)/lib/modules
	$(Q)rm -rf $(USERFS_DIR)/usr/share/terminfo && \
	mkdir -p $(USERFS_DIR)/usr/share && \
	mv $(RUNTIME_DIR)/usr/share/terminfo $(USERFS_DIR)/usr/share/terminfo && \
	ln -s /mnt/ufs/usr/share/terminfo $(RUNTIME_DIR)/usr/share/terminfo && \
	mv $(RUNTIME_DIR)/usr/bin/rmsync $(USERFS_DIR)/root/retain/rmsync && \
	mv $(RUNTIME_DIR)/usr/bin/rmsync.cfg.in $(USERFS_DIR)/root/retain/rmsync.cfg.in && \
	sed -i -e '/spi0\.2/s/^RET/#RET/;/retain.bin/a RETAIN_FILE=/sys/bus/spi/devices/spi3.0/eeprom' \
	    $(USERFS_DIR)/root/retain/rmsync.cfg.in && \
	rm -f $(USERFS_DIR)/root/CoDeSysSP/codesyssp && \
	ln -s /usr/bin/codesyssp $(USERFS_DIR)/root/CoDeSysSP/codesyssp && \
	cat $(PLATFORMS_DIR)/$(BUILDCONF)/ufiles/root/$(BUILDCONF).tar | \
	    (cd $(USERFS_DIR)/root; tar xp) && \
	cat $(PLATFORMS_DIR)/$(BUILDCONF)/ufiles/root/cdw.tar | \
	    (cd $(USERFS_DIR)/root; tar xp) && \
	rm $(USERFS_DIR)/root/cdw.tar && \
	cp $(USERFS_DIR)/root/CoDeSysSP/*.cfg $(RUNTIME_DIR)/etc/CoDeSysSP/ && \
	cp $(USERFS_DIR)/root/uartmode $(RUNTIME_DIR)/usr/bin/ && \
	cp -rp $(RUNTIME_DIR)/etc/* $(RUNTIME_DIR)/mnt/etcro && \
	rm -f $(USERFS_DIR)/root/$(BUILDCONF).tar

ubicfg:
	$(Q)echo -e \
	"[ubifs]\n"\
	"mode=ubi\n"\
	"image=ubifs.img\n"\
	"vol_id=0\n"\
	"vol_size=218MiB\n"\
	"vol_type=dynamic\n"\
	"vol_name=uservolume\n"\
	"vol_flags=autoresize\n"\
	> $(BOOTSYS_DIR)/ubinize.cfg

jfsimg:
	$(Q)$(call do-fakeroot-inst,$(MAKE) imgprep)

imgprep:
	$(Q){ cd $(BOOTSYS_DIR); \
	    $(TARGET_DIR)/bin/mkfs.ubifs -v -r userfs \
	    -o user.fs -m 2048 -e 126976 -c 1700; }

cramfsimg fsimg:
	$(Q)$(call do-fakeroot-inst,$(MAKE) imgprep)
	$(Q)$(call do-fakeroot-inst,$(MAKE) cramprep)
	$(Q)echo -e \
	"0x80000\n"\
	"0x280000\n"\
	"0x780000\n"\
	"0x3DC0000\n"\
	"setenv bootcmd 'nand read 81600000 280000 500000;bootm 81600000'\n"\
	"setenv bootargs '$(BOOT_ARGS)'\n"\
	"setenv mtdparts '$(MTD_PARTS)'\n"\
	"setenv mtdids 'nand0=omap2-nand.0'" > $(BOOTSYS_DIR)/uconf.txt
	$(Q)$(BASEDIR)/scripts/make_off_script_var.sh $(FLASH_TYPE) $(FLASH_SIZE) \
	    "$(BOOT_ARGS)" $(MTD_PARTS_SHIFT) $(MACH) $(BOOTSYS_DIR)/boot \
	    $(TARGET_DIR)/bin > /dev/null
	$(Q){ cd $(BOOTSYS_DIR); \
		$(BASEDIR)/scripts/mkfw.sh spk207f.bin $(MACH) full "$(UBOOT_BOARD_NAME)" "$(UBOOT_BOARD_FULL_NAME)" "$(BOOT_ARGS)" $(shell printf "%u.%03u" `expr $(BUILD_VERSION) / 1000` `expr $(BUILD_VERSION) % 1000`); }

cramprep:
	$(Q){ cd $(BOOTSYS_DIR); \
	    $(TARGET_DIR)/bin/mkfs.ubifs -v -r runtime \
	    -o plc.fs -m 2048 -e 126976 -c 448; }

tarimg:
	$(Q)$(call do-fakeroot-inst,$(MAKE) tarprep)

tarprep:
	$(Q){ cd $(BOOTSYS_DIR); \
	    $(TAR) $(TAR_OPTS) runtime.tar runtime; \
	    $(TAR) $(TAR_OPTS) ufs.tar userfs; }
