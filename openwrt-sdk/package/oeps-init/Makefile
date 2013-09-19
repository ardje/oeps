# 
# Copyright (C) 2006-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=oeps-init
PKG_VERSION:=1.0.16
PKG_RELEASE:=30

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/oeps-init
  SECTION:=utils
  CATEGORY:=Base system
  DEPENDS:=+ip +luci-ssl +kmod-gre +tcpdump +kmod-ath9k +wpad +ebtables +coreutils-timeout
  TITLE:=Openwrt Enterprise Provisioning System
  PKGARCH:=all
endef

define Package/oeps-init/description
 Auto install and configures openwrt supported accesspoints
 Manage accesspoints from a central configuration database
 to enable the quick update and runin of large roaming networks
 of access points.
endef

define Package/oeps-init/conffiles
/etc/config/oeps
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/oeps-init/install
	$(INSTALL_DIR) $(1)
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,oeps-init))

