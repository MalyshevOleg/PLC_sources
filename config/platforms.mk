PLATFORMS_DIR  = $(BASEDIR)/config/platforms
PLATFORMS_LIST = $(shell cat $(PLATFORMS_DIR)/platf.list)
PLATFORMS_AVAIL = $(notdir $(wildcard $(addprefix ${PLATFORMS_DIR}/,$(PLATFORMS_LIST))))
MN_SET = $(shell cat $(PLATFORMS_DIR)/platf.list | grep -v '^$$' | awk '{print $$1 " \"" $$1 "\"" }' )

targ ?= base-system

ifeq ($(strip $(BUILDCONF)),)
top distclean:
	$(Q)$(MAKE) help
else
top:
	$(Q)$(MAKE) $(targ)

include $(PLATFORMS_DIR)/$(BUILDCONF)/Makefile

distclean:
	@(for t in $(BUILDCONF); do \
	    BASETARG="clean-total" \
		$(MAKE) -C $(PLATFORMS_DIR)/$$t/ cmd-basedir-env; \
	    $(MAKE) -C $(PLATFORMS_DIR)/$$t/ distclean; \
	done)
endif

help:
	@echo "1. Check(edit) the config/configvars.mk"
	@echo "- Set BUILD_ROOT, TARGET_DIR"
	@echo "- DOWNLOAD_DIR (if you already have some downloaded sources, put them there)"
	@echo "- To have the toolchain download all the current sources."
	@echo -e "  make targ=\"source_targets\""
	@echo "- For BUILDCONF options: make confs-list"
	@echo "- After BUILDCONF is set and make has completed,"
	@echo "   these additional targ=\"\" targets will work:"
	@echo "   - $(DEF_CONF_TARGS)"
	@echo "   eg. To rebuild linux: make targ=\"linux-rebuild re-install\""
	@echo "- Other examples after a BUILDCONF build."
	@echo -e "  PREMAKE=\"PATH=\\\$$(TARGET_PATH)/bin:\\\$$\\\$$PATH\" make targ=\"-C \\\$$(UCLIBC_PATH) menuconfig\""
	@echo -e "  PREMAKE=\"PATH=\\\$$(TARGET_PATH)/bin:\\\$$\\\$$PATH\" BASETARG=\"-C \\\$$(KERNEL_PATH) modules SUBDIRS=drivers/usb\" make targ=\"cmd-basedir-env\""
	@echo "  BASETARG=\"tplay\" make targ=\"cmd-basedir-env\""
	@echo "- To list top level targets: make top-targs-list"
	@echo "- To completely clean the toolchain: make distclean"
	@echo -e "- To build all 2410 based targets: \n\tfor t in \$$$\(make list-confs | grep -E \"(sa2410|apollo)\"); do make HOST_CC=gcc-3.4 BUILDCONF=\"\$$t\"; done"

platforms-list:
	@(for f in $(PLATFORMS_AVAIL); do echo $$f; done)



#	@$(SED) "s/^BUILDCONF=.*$/BUILDCONF=$(RES)//" $(BASEDIR)/config/configvars.mk 



menuconfig:
	$(Q){ tmpf=`mktemp tmpselXXXXXX`; \
           dialog --clear --title "Select a target" --ascii-lines --menu "Choose one of the TARGET PLC" 30 60 60 $(MN_SET) 2>$$tmpf; \
           sel=`cat $$tmpf`; rm $$tmpf; \
           sed -i "s/^BUILDCONF=.*$$/BUILDCONF=$$sel/" $(BASEDIR)/config/configvars.mk; }
		

	
#sed "s/^BUILDCONF=.*$/BUILDCONF=$(SELECT_PLC)//" $(BASEDIR)/config/configvars.mk 
	


#	@echo $(SED) "s/BUILDCONF=spk105/BUILDCONF=$(RES)//" $(BASEDIR)/config/configvars.mk 
	
source-targets-list:
	@(for f in $(SOURCE_TARGETS); do echo $$f; done)

source-targets:
	$(call print-info,fetching all the required source packages)
	@$(MAKE) -s $(SOURCE_TARGETS)
