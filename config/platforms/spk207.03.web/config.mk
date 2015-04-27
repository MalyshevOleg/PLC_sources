include $(PLATFORMS_DIR)/common/defconfig.mk

KERNEL_DEFCONFIG=owen_spk207_var_defconfig
XLOADER_DEFCONFIG=owen_spk2xx_var_config
BOOT_DEFCONFIG=owen_spk2xx_var07_config

UBOOT_LOGO=$(UBOOT_SDIR)/board/owen/spk2xx_var07/logo.h
UBOOT_BOARD_NAME=spk207.03.web
UBOOT_BOARD_FULL_NAME=spk207.03.web

TARG_HOSTNAME=spk207.03.web

ROOTFS_DEVICE=/dev/mtdblock2
ROOTFS_TYPE=ubifs

GFX_VERS = 4.08.00.01
GFX_VERS_BASE = 4.08.00.01
GFXKM_VERS = 4.08.00.01
GFXKM_VERS_BASE = 4.08.00.01

UART_DEV=ttyS0
UART_BAUD=115200

FLASH_TYPE=NAND
FLASH_SIZE=0x10000000
MTD_PARTS=mtdparts=omap2-nand.0:0x80000(xloader),0x200000(u-boot),0x500000(kernel),0x3640000(rootfs),-(userfs)
BOOT_ARGS=$(MTD_PARTS) mem=128M root=ubi0:rfs rootfstype=ubifs ro ubi.mtd=3 ubi.mtd=4 console=$(UART_DEV),$(UART_BAUD)n8
# needed for detecting UBI parts by their indexes specified via ubi.mtd=
MTD_PARTS_SHIFT=0
