# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

inherit qt5-module

DESCRIPTION="The Qt toolkit is a comprehensive C++ application development framework"

if [[ ${QT5_BUILD_TYPE} == live ]]; then
	KEYWORDS=""
else
	KEYWORDS="~amd64"
fi

IUSE="localstorage"

# TODO: easingcurveeditor|qmlscene? ( qt-widgets )
# TODO: xml? ( qt-xmlpatterns )

DEPEND="
	~x11-libs/qt-core-${PV}[debug=]
	~x11-libs/qt-gui-${PV}[debug=]
	~x11-libs/qt-jsbackend-${PV}[debug=]
	~x11-libs/qt-network-${PV}[debug=]
	~x11-libs/qt-test-${PV}[debug=]
	localstorage? ( ~x11-libs/qt-sql-${PV}[debug=] )
"
RDEPEND="${DEPEND}"

src_prepare() {
	qt5-module_src_prepare

	use localstorage || sed -i -e '/localstorage/d' \
		src/imports/imports.pro || die

	# Fix sandbox violation
	sed -i -e '/DESTDIR/ s|QT\.gui\.|QT.quick.|' \
		src/plugins/accessible/quick/quick.pro || die
}