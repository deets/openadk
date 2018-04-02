# This file is part of the OpenADK project. OpenADK is copyrighted
# material, please see the LICENCE file in the top-level directory.

include $(ADK_TOPDIR)/rules.mk

PKG_NAME:=		pyserial
PKG_VERSION:=		3.2.1
PKG_RELEASE:=		1
PKG_HASH:=		1eecfe4022240f2eab5af8d414f0504e072ee68377ba63d3b6fe6e66c26f66d1
PKG_DESCR:=		python serial communication library
PKG_SECTION:=		sys/serial
PKG_DEPENDS:=		python3
PKG_BUILDDEP:=		python3
PKG_URL:=		https://github.com/pyserial/pyserial
PKG_SITES:=		https://github.com/pyserial/pyserial/releases/download/v${PKG_VERSION}/

DISTFILES:=		pyserial-${PKG_VERSION}.tar.gz


include $(ADK_TOPDIR)/mk/package.mk

$(eval $(call PKG_template,PYSERIAL,pyserial,$(PKG_VERSION)-${PKG_RELEASE},${PKG_DEPENDS},${PKG_DESCR},${PKG_SECTION}))

CONFIG_STYLE:=		manual
BUILD_STYLE:=		manual
INSTALL_STYLE:=		manual

include $(ADK_TOPDIR)/mk/python3.mk

do-build:
	cd $(WRKBUILD); env PYTHONPATH=$(PYTHON3_LIBDIR) $(PYTHON3) ./setup.py build 
	cd $(WRKBUILD); env PYTHONPATH=$(PYTHON3_LIBDIR) $(PYTHON3) ./setup.py install --single-version-externally-managed --prefix=/usr --root="$(WRKINST)"

do-install:
	$(INSTALL_DIR) $(IDIR_PYSERIAL)/usr/bin
	$(INSTALL_DIR) $(IDIR_PYSERIAL)/usr/lib/python$(PYTHON3_VERSION)
	$(CP) $(WRKINST)/usr/lib/python$(PYTHON3_VERSION)/* $(IDIR_PYSERIAL)/usr/lib/python$(PYTHON3_VERSION)

include ${ADK_TOPDIR}/mk/pkg-bottom.mk
