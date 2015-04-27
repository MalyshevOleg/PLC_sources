BINCROSS_NAME=owen-cross-1

toolchain-deb: $(TOOLCHAIN_DIR)/.toolchain
	$(Q)($(SUDO) rm -rf $(PKGINST_DIR); \
	    mkdir -p $(PKGINST_DIR)/debian/DEBIAN; \
	    mkdir -p $(PKGINST_DIR)/debian/$(TARGET_DIR); \
	    chmod g-s $(PKGINST_DIR)/debian/DEBIAN )
	$(Q)$(SUDO) $(CP) $(TARGET_DIR)/* \
	    $(PKGINST_DIR)/debian/$(TARGET_DIR)
	$(Q)echo -e \
	"Package: owen-cross-4.3.2\n"\
	"Version: 1.0\n"\
	"Section: development\n"\
	"Priority: optional\n"\
	"Architecture: all\n"\
	"Essential: no\n"\
	"Depends:\n"\
	"Pre-Depends:\n"\
	"Recommends:\n"\
	"Suggests:\n"\
	"Maintainer: Oleg Oleshko <h2o@softerra.com>\n"\
	"Provides:\n"\
	"Description: A cross compiler\n"\
	> $(PKGINST_DIR)/debian/DEBIAN/control
	$(Q)echo "#!/bin/sh" \
	> $(PKGINST_DIR)/debian/DEBIAN/postinst
	$(Q)echo "#!/bin/sh" \
	> $(PKGINST_DIR)/debian/DEBIAN/prerm
	$(Q)chmod +x $(PKGINST_DIR)/debian/DEBIAN/{postinst,prerm}
# remove trash
	$(Q)$(SUDO) rm -rf $(PKGINST_DIR)/debian/$(TARGET_DIR)/share/{info,man}
	$(Q)$(SUDO) rm `find $(PKGINST_DIR)/debian/$(TARGET_DIR) -type f -a -perm -o=x | \
	    xargs file | grep "executable, ARM" | awk -F : '{print $$1}'`
	$(Q)(cd $(PKGINST_DIR) && \
	    $(SUDO) dpkg-deb --build debian . && \
	    $(CP) owen-cross-4.3.2_1.0_all.deb $(BINARIES_DIR)/ && \
	    $(SUDO) rm -rf $(PKGINST_DIR))

toolchain-tgz: $(TOOLCHAIN_DIR)/.toolchain
	$(Q)($(SUDO) rm -rf $(PKGINST_DIR); \
	    mkdir -p $(PKGINST_DIR)$(TARGET_DIR) )
	$(Q)$(SUDO) $(CP) $(TARGET_DIR)/* \
	    $(PKGINST_DIR)$(TARGET_DIR)
# remove trash
	$(Q)$(SUDO) rm -rf $(PKGINST_DIR)$(TARGET_DIR)/share/{info,man} && \
	$(SUDO) rm `find $(PKGINST_DIR)$(TARGET_DIR) -type f -a -perm -o=x | \
	    xargs file | grep "executable, ARM" | awk -F : '{print $$1}'`
	$(Q)(cd $(PKGINST_DIR) &&  \
	    $(call sudopath,PATH=$(TARGET_DIR)/bin:$$PATH) \
		$(MAKEPKG) $(BINCROSS_NAME).tgz \
		    $(call do-log,$(TOOLCHAIN_DIR)/makepkg.out) && \
	    $(CP) $(PKGINST_DIR)/$(BINCROSS_NAME).tgz $(BINARIES_DIR)/ && \
	    $(SUDO) rm -rf $(PKGINST_DIR))
