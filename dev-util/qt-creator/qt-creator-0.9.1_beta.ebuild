# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EGIT_BRANCH="0.9.1-beta"

inherit qt4 multilib git

DESCRIPTION="Lightweight IDE for C++ development centering around Qt"
HOMEPAGE="http://trolltech.com/developer/qt-creator"

EGIT_REPO_URI="git://labs.trolltech.com/qt-creator/"

LICENSE="|| ( GPL-2 GPL-3 )"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug"

DEPEND="=x11-libs/qt-assistant-4.5*
	=x11-libs/qt-core-4.5*
	=x11-libs/qt-dbus-4.5*
	=x11-libs/qt-gui-4.5*
	=x11-libs/qt-qt3support-4.5*
	=x11-libs/qt-script-4.5*
	=x11-libs/qt-sql-4.5*
	=x11-libs/qt-svg-4.5*
	=x11-libs/qt-test-4.5*
	=x11-libs/qt-webkit-4.5*"

RDEPEND="${DEPEND}
	|| ( media-sound/phonon =x11-libs/qt-phonon-4.5* )"

src_unpack() {
	git_src_unpack
	#fixing headers,qtcreator.pro file and docs path
	einfo "Applying various patches and fixes"
	# patching the docs_path patch in order to fix every release of qt-creator
	epatch ${FILESDIR}/fix_headers.patch
	epatch ${FILESDIR}/qtcreator_pro.patch
	epatch ${FILESDIR}/docs_path.patch
	epatch ${FILESDIR}/templates.patch
	epatch ${FILESDIR}/license.patch
	sed -i "s/docs\/qt-creator/docs\/${PF}/" ${S}/src/plugins/help/helpplugin.cpp
	sed -i "s/docs\/qt-creator/docs\/${PF}/" ${S}/src/app/app.pro
	#adding paths
	echo "bin.path = /usr/bin" >> "${S}"/qtcreator.pro
	echo "libs.path = /usr/$(get_libdir)" >> "${S}"/qtcreator.pro
	echo "docs.path = /usr/share/docs/${PF}" >> "${S}"/qtcreator.pro
	# fix qtcreator.qch placement
	sed -i "s/html\/qtcreator.qhp/docs\/${PF}\/html\/qtcreator.qhp/" ${S}/doc/doc.pri
	sed -i "s/qtcreator.qch/docs\/${PF}\/qtcreator.qch/" ${S}/doc/doc.pri
}

src_compile() {
	eqmake4 qtcreator.pro || die "eqmake4 failed"
	emake || die "emake failed"
}

src_install() {
	emake INSTALL_ROOT="${D}" install || die "emake install failed"
	dobin bin/qtcreator || die "dobin failed"
	# installing several templates , desinger etc under /usr/share/qt-creator/
	insinto /usr/share/qt-creator/ || die "insinto failed"
	for i in designer gdbmacros schemes snippets templates; do
		doins -r ${S}/bin/${i} || die  "doins failed"
	done
	# install licence
	doins ${S}/bin/license.txt || die "doins license.txt failed"
	# installing libraries as the Makefile doesnt
	insinto /usr/$(get_libdir)/ || die "insinto failed"
	doins -r lib/* || die "doins failed"
	# need to delete the broken symlinks
	cd "${D}"/usr/$(get_libdir)/
	rm -v libAggregation.so{,.1,.1.0} libCPlusPlus.so{,.1,.1.0} libExtensionSystem.so{,.1,.1.0}
	rm -v libQtConcurrent.so{,.1,.1.0} libUtils.so{,.1,.1.0}
	einfo "Creating symlinks"
	# the symlinks arent kept from the ${S} folder so I need to 
	# recreate them on destination folder.
	for lib in Aggregation CPlusPlus ExtensionSystem QtConcurrent Utils ; do
		ln -s lib${lib}.so.1.0.0 lib${lib}.so || die "dosym failed"
		ln -s lib${lib}.so.1.0.0 lib${lib}.so.1 || die "dosym failed"
		ln -s lib${lib}.so.1.0.0 lib${lib}.so.1.0 || die "dosym failed"
	done
	make_desktop_entry qtcreator QtCreator designer.png \
		'Qt;Development;GUIDesigner' || die "make_desktop_entry failed"
}
