# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-qt/qtwebkit/qtwebkit-4.8.6-r1.ebuild,v 1.1 2014/11/15 02:38:53 pesa Exp $

EAPI=5
PYTHON_COMPAT=( python2_7 )
inherit eutils multilib python-any-r1 qmake-utils toolchain-funcs multilib-minimal

DESCRIPTION="The WebKit module for the Qt toolkit"
HOMEPAGE="https://www.qt.io/"
SRC_URI="http://dev.gentoo.org/~kensington/distfiles/${P}.tar.xz"

LICENSE="|| ( LGPL-2.1 GPL-3 )"
SLOT="4"
KEYWORDS="~amd64"
IUSE="debug +gstreamer"

RDEPEND="
	>=dev-db/sqlite-3.8.3:3[${MULTILIB_USEDEP}]
	dev-libs/libxml2:2[${MULTILIB_USEDEP}]
	dev-libs/libxslt[${MULTILIB_USEDEP}]
	>=dev-qt/qtcore-4.8.6-r1:4[ssl,${MULTILIB_USEDEP}]
	>=dev-qt/qtdeclarative-4.8.6-r1:4[${MULTILIB_USEDEP}]
	>=dev-qt/qtgui-4.8.6-r1:4[${MULTILIB_USEDEP}]
	>=dev-qt/qtopengl-4.8.6-r1:4[${MULTILIB_USEDEP}]
	>=dev-qt/qtscript-4.8.6-r1:4[${MULTILIB_USEDEP}]
	>=dev-qt/qtsql-4.8.6-r1:4[sqlite,${MULTILIB_USEDEP}]
	>=media-libs/fontconfig-2.10.2-r1[${MULTILIB_USEDEP}]
	media-libs/libpng:0=[${MULTILIB_USEDEP}]
	>=sys-libs/zlib-1.2.8-r1[${MULTILIB_USEDEP}]
	virtual/jpeg:0[${MULTILIB_USEDEP}]
	virtual/libudev:=[${MULTILIB_USEDEP}]
	>=virtual/opengl-7.0-r1[${MULTILIB_USEDEP}]
	x11-libs/libX11[${MULTILIB_USEDEP}]
	x11-libs/libXrender[${MULTILIB_USEDEP}]
	gstreamer? (
		dev-libs/glib:2[${MULTILIB_USEDEP}]
		media-libs/gstreamer:1.0[${MULTILIB_USEDEP}]
		media-libs/gst-plugins-base:1.0[${MULTILIB_USEDEP}]
	)
"
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	dev-lang/perl
	dev-lang/ruby
	dev-util/gperf
	sys-devel/bison
	sys-devel/flex
	virtual/perl-Digest-MD5
	virtual/perl-File-Spec
	virtual/perl-Getopt-Long
"

src_prepare() {
	# examples cause a sandbox violation (bug 458222)
	sed -i -e '/SUBDIRS += examples/d' Source/QtWebKit.pro || die

	# respect CXXFLAGS
	sed -i -e '/QMAKE_CXXFLAGS_RELEASE.*=/d' \
		Source/WTF/WTF.pro \
		Source/JavaScriptCore/Target.pri || die

	epatch "${FILESDIR}"/${PN}-2.3.4-use-correct-typedef.patch
	epatch_user
}

multilib_src_compile() {
	local -x \
		QTDIR=${EPREFIX}/usr/$(get_libdir)/qt4 \
		WEBKITOUTPUTDIR=${BUILD_DIR}

	local myconf=(
		"${S}"/Tools/Scripts/build-webkit
		--qt
		# tell the build system where to find the qmake binary for the current ABI
		--qmake="$(qt4_get_bindir)"/qmake
		--qmakearg="CONFIG+=nostrip CONFIG+=production_build DEFINES+=HAVE_QTTESTLIB=0"
		--makeargs="${MAKEOPTS}"
		--$(usex debug debug release)
		--$(usex gstreamer video no-video)
		--no-webkit2
		# copied from eqmake4
		QMAKE_AR="'$(tc-getAR) cqs'"
		QMAKE_CC="'$(tc-getCC)'"
		QMAKE_CXX="'$(tc-getCXX)'"
		QMAKE_LINK="'$(tc-getCXX)'"
		QMAKE_LINK_C="'$(tc-getCC)'"
		QMAKE_OBJCOPY="'$(tc-getOBJCOPY)'"
		QMAKE_RANLIB=
		QMAKE_STRIP=
		QMAKE_CFLAGS="'${CFLAGS}'"
		QMAKE_CFLAGS_RELEASE=
		QMAKE_CFLAGS_DEBUG=
		QMAKE_CXXFLAGS="'${CXXFLAGS}'"
		QMAKE_CXXFLAGS_RELEASE=
		QMAKE_CXXFLAGS_DEBUG=
		QMAKE_LFLAGS="'${LDFLAGS}'"
		QMAKE_LFLAGS_RELEASE=
		QMAKE_LFLAGS_DEBUG=
	)
	echo "${myconf[@]}"
	"${myconf[@]}" || die
}

multilib_src_install() {
	emake INSTALL_ROOT="${D}" install -C $(usex debug Debug Release)
}
