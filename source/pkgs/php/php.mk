# Package: PHP
PHP_VERS = 5.3.15
PHP_EXT  = tar.bz2
PHP_SITE = http://de.php.net/distributions
PHP_PDIR = pkgs/php

PHP_CONFIG_VARS = PATH=$(TARGET_DIR)/bin:$$PATH CFLAGS="-Os" \
    CC=$(TARGET)-gcc \
    ac_cv_func_libiconv=yes
PHP_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(TARGET) \
    --target=$(TARGET) \
    --prefix=/usr \
    --disable-short-tags \
    --without-mysql \
    --without-pear \
    --disable-all \
    --disable-short-tags \
    --enable-force-cgi-redirect \
    --enable-discard-path \
    --enable-json \
    --enable-session \
    --with-iconv=$(TARGET_DIR)/$(TARGET)

PHP_MAKE_VARS = PATH=$(TARGET_DIR)/bin:$$PATH

PHP_RUNTIME_INSTALL = y
PHP_DEPS = LIBICONV

PHP_POSTHOSTINST = +$(call do-fakeroot,$(MAKE) php-rt) \
    $(call autoclean,php-dirclean)

$(eval $(call create-common-defs,php,PHP,-))

$(PHP_DIR)/.hostinst: $(PHP_DIR)/.built
	$(Q)touch $@

php-rt:
	$(Q){ rm -rf $(PHP_INSTDIR) && \
	mkdir -p $(PHP_INSTDIR) && \
	    PATH=$(TARGET_DIR)/bin:$$PATH INSTALL_ROOT=$(PHP_INSTDIR) \
	    $(MAKE) -C $(PHP_BDIR) \
	    install \
	    $(call do-log,$(PHP_BDIR)/posthostinst.out); }
	$(Q)(cd $(PHP_INSTDIR); \
	    rm -f usr/bin/php usr/bin/php-config usr/bin/phpize && \
	    rm -rf usr/include usr/lib usr/man; \
	    mkdir etc && touch etc/php.ini; \
	    echo -e \
		"doc_root=/root/www\n"\
		"date.timezone=\"Europe/Moscow\""\
	    > etc/php.ini; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
		$(TARGET)-strip --strip-all usr/bin/*; \
	    PATH=$(TARGET_DIR)/bin:$$PATH \
	    $(MAKEPKG) php-$(PHP_VERS).tgz \
		$(call do-log,$(PHP_BDIR)/makepkg.out) && \
	    mv php-$(PHP_VERS).tgz $(BINARIES_DIR)/arm$(MACH)-runtime/ ;)
	$(Q)rm -rf $(PHP_INSTDIR)
