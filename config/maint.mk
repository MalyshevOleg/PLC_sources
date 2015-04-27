BUILDSYS_TOP_DIRS  = config docs mkdebug scripts source
BUILDSYS_TOP_FILES = INSTALL Makefile README
BUILDSYS_TEMP_DIR  = $(BUILD_ROOT)/temp

PLATFORMS ?= $(firstword $(PLATFORMS_AVAIL))
TARNAME   ?= buildsys.tar

PLATFORMS_DIRS = $(shell \
    for dir in $(wildcard $(PLATFORMS_DIR)/*); do \
    if [ -d $$dir ]; then \
        echo $$dir; \
    fi; done)

PLATFORMS_ALL  = $(notdir $(PLATFORMS_DIRS))
PLATFORMS2DEL1 = $(filter-out $(PLATFORMS_AVAIL) common,$(PLATFORMS_ALL))
PLATFORMS2DEL2 = $(filter-out $(PLATFORMS),$(PLATFORMS_AVAIL))

ifeq "$(words $(PLATFORMS))" "0"

maint-package:
	@echo "Error: No platforms specified."
	@echo "Sample: make PLATFORMS=\"hermes pegasus\" maint-package"

else

maint-package:
	$(Q)mkdir -p $(BUILDSYS_TEMP_DIR)
	$(Q)$(CP) $(BUILDSYS_TOP_DIRS) $(BUILDSYS_TOP_FILES) \
	    $(BUILDSYS_TEMP_DIR)
	$(Q)$(SUDO) find $(BUILDSYS_TEMP_DIR) -name .svn | \
	    xargs $(SUDO) rm -rf
	for item in $(PLATFORMS2DEL1) $(PLATFORMS2DEL2); do \
	    rm -rf $(BUILDSYS_TEMP_DIR)/config/platforms/$$item; \
	done
	for item in $(PLATFORMS2DEL2); do \
	    $(SED) -i -e "/^$$item$$/d" \
		$(BUILDSYS_TEMP_DIR)/config/platforms/platf.list; \
	done
	rm -f $(BUILDSYS_TEMP_DIR)/config/maint.mk
	$(Q)$(SED) -i -e '/maint\.mk/d' $(BUILDSYS_TEMP_DIR)/Makefile
	$(Q)(cd $(BUILDSYS_TEMP_DIR); \
	    $(TAR) $(TAR_OPTS) $(TARNAME) .; \
	    $(CP) $(TARNAME) $(BASEDIR); \
	    rm -rf $(BUILDSYS_TEMP_DIR))

endif
