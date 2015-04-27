include $(PLATFORMS_DIR)/common/defconfig.mk

#KERNEL_DEFCONFIG = hermes-mtd_defconfig
KERNEL_DEFCONFIG = owen_plc323_defconfig

BOOT_DEFCONFIG = owen_plc323_config
ROMBOOT_IDENT = PLC304
ROMBOOT_MSIZE = 16M
UBOOT_LOADADDR = 0x207d0000

UBOOT_BOARD_NAME=plc323
UBOOT_BOARD_FULL_NAME=plc323

UBOOT_ENV_SIZE=0x8000

TARG_HOSTNAME=plc323cds
WEBCONFIG_DEF=OWEN_PLC323

ROOTFS_DEVICE=/dev/mtdblock3
ROOTFS_TYPE=squashfs

UART_DEV=ttyS0
UART_BAUD=115200

FLASH_TYPE=NOR
FLASH_SIZE=0x01000000
FLASH_BASE=0x10000000
FLASH_ERASE_SIZE=0x20000
MTD_PARTS=mtdparts=physmap-flash.0:0x40000(u-boot),0x20000(u-boot-env),0x160000(kernel),0x440000(rootfs),-(userfs)
BOOT_ARGS=$(MTD_PARTS) root=$(ROOTFS_DEVICE) ro ubi.mtd=4 console=$(UART_DEV),$(UART_BAUD) mem=32M plc323 quiet
# needed for detecting UBI parts by their indexes specified via ubi.mtd=
MTD_PARTS_SHIFT=0
