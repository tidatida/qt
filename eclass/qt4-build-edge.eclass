# Copyright 2007-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# @ECLASS: qt4-build-edge.eclass
# @MAINTAINER:
# Ben de Groot <yngwin@gentoo.org>
# Christian Franke <cfchris6@ts2server.com>
# Markos Chandras <hwoarang@silverarrow.gr>
# @BLURB: Eclass for Qt4 split ebuilds in qting-edge overlay.
# @DESCRIPTION:
# This eclass contains various functions that are used when building Qt4
# Based on the qt4-build eclass by Caleb Tennis <caleb@gentoo.org>

# WARNING: This eclass now requires EAPI=2
#
# NOTES:
#
#	4.9999 stands for live ebuilds from qtsoftware's git repository
#			(that is nokia, previously trolltech)
#	4.?.9999 stands for live ebuilds from kdesvn repository
#	4.*.*_{beta,rc,}* and * are releases or snapshots from qtsoftware
#

IUSE="${IUSE} -custom-cxxflags debug pch"

case "${PV}" in
	4.?.9999)
		inherit eutils multilib toolchain-funcs flag-o-matic subversion
		;;
	4.9999)
		inherit eutils multilib toolchain-funcs flag-o-matic git versionator
		;;
	*)
		inherit eutils multilib toolchain-funcs flag-o-matic
		;;
esac

case "${PV}" in
	4.*.*_beta*)
		SRCTYPE="${SRCTYPE:-opensource-src}"
		MY_PV="${PV/_beta/-beta}"
		;;
	4.*.*_rc*)
		SRCTYPE="${SRCTYPE:-opensource-src}"
		MY_PV="${PV/_rc/-rc}"
		;;
	*)
		SRCTYPE="${SRCTYPE:-opensource-src}"
		MY_PV="${PV}"
		;;
esac
MY_P=qt-x11-${SRCTYPE}-${MY_PV}
S=${WORKDIR}/${MY_P}

SRC_URI="ftp://ftp.trolltech.com/qt/source/${MY_P}.tar.bz2"

case "${PV}" in
	4.?.9999)
		HOMEPAGE="http://websvn.kde.org/trunk/qt-copy/";;
	*)
		HOMEPAGE="http://www.qtsoftware.com/";;
esac

case "${PV}" in
	4.?.9999)
		ESVN_REPO_URI="svn://anonsvn.kde.org/home/trunk/qt-copy"
		ESVN_PROJECT="qt-copy"
		SRC_URI=
		;;
	4.9999)
		EGIT_REPO_URI="git://labs.trolltech.com/qt/all"
		EGIT_PROJECT="qt-${PV}"
		SRC_URI=
		;;
	4.4.?)
		SRC_URI="${SRC_URI} mirror://gentoo/${MY_P}-headers.tar.bz2"
		;;
	*)
		;;
esac

qt4-build-edge_pkg_setup() {
	# Set up installation directories
	QTBASEDIR=/usr/$(get_libdir)/qt4
	QTPREFIXDIR=/usr
	QTBINDIR=/usr/bin
	QTLIBDIR=/usr/$(get_libdir)/qt4
	QTPCDIR=/usr/$(get_libdir)/pkgconfig
	QTDATADIR=/usr/share/qt4
	QTDOCDIR=/usr/share/doc/qt-${PV}
	QTHEADERDIR=/usr/include/qt4
	QTPLUGINDIR=${QTLIBDIR}/plugins
	QTSYSCONFDIR=/etc/qt4
	QTTRANSDIR=${QTDATADIR}/translations
	QTEXAMPLESDIR=${QTDATADIR}/examples
	QTDEMOSDIR=${QTDATADIR}/demos

	PLATFORM=$(qt_mkspecs_dir)

	PATH="${S}/bin:${PATH}"
	LD_LIBRARY_PATH="${S}/lib:${LD_LIBRARY_PATH}"

	# Make sure ebuilds use the required EAPI
	if [[ $EAPI != 2 ]]; then
		ewarn "The qt4-build-edge eclass requires EAPI=2, but this ebuild does not"
		ewarn "have EAPI=2 set. The ebuild author or editor failed. This ebuild needs"
		ewarn "to be fixed. Using qt4-build-edge eclass without EAPI=2 will fail."
		die "qt4-build-edge eclass requires EAPI=2 set"
	fi

	# Let users know what they are getting themselves into ;-)
	echo
	case "${PV}" in
		4.?.9999)
			ewarn "The ${PV} version ebuilds install qt-copy from KDE's subversion repo"
			;;
		4.9999)
			ewarn "The ${PV} version ebuilds install live git code from Nokia Qt Software"
			;;
		4.*.*_*)
			ewarn "The ${PV} version ebuilds install a pre-release from Nokia Qt Software"
			;;
		*)
			;;
	esac
	echo

	if ! version_is_at_least 4.1 $(gcc-version) ; then
		ewarn "Using a GCC version lower than 4.1 is not supported!"
		echo
	fi
}

qt4-build-edge_src_unpack() {
	local target targets
	for target in configure LICENSE.{GPL2,GPL3} projects.pro \
		src/{qbase,qt_targets,qt_install}.pri bin config.tests mkspecs qmake \
		${QT4_EXTRACT_DIRECTORIES}; do
			targets="${targets} ${MY_P}/${target}"
	done

	case "${PV}" in
		4.?.9999)
			ESVN_REPO_FREQ=${ESVN_UP_FREQ:-1}
			subversion_src_unpack
			;;
		4.9999)
			git_src_unpack
			;;
		*)
			echo tar xjpf "${DISTDIR}"/${MY_P}.tar.bz2 ${targets}
			tar xjpf "${DISTDIR}"/${MY_P}.tar.bz2 ${targets}
			;;
	esac

	# For 4.4.x releases we supply a prepackaged headers tarball
	case "${PV}" in
		4.4.?)
			echo tar xjpf "${DISTDIR}"/${MY_P}-headers.tar.bz2
			tar xjpf "${DISTDIR}"/${MY_P}-headers.tar.bz2
			;;
	esac
}

qt4-build-edge_src_prepare() {
	case "${PV}" in
		4.?.9999)
			# apply KDE patchset
			cd "${S}"
			python apply_patches.py || die "Applying KDE patchset failed"
			;;
	esac

	if [[ ${PN} != qt-core ]]; then
		cd "${S}"
		skip_qmake_build_patch
		skip_project_generation_patch
		symlink_binaries_to_buildtree
	fi

	sed -e "s:QMAKE_CFLAGS_RELEASE.*=.*:QMAKE_CFLAGS_RELEASE=${CFLAGS}:" \
		-e "s:QMAKE_CXXFLAGS_RELEASE.*=.*:QMAKE_CXXFLAGS_RELEASE=${CXXFLAGS}:" \
		-e "s:QMAKE_LFLAGS_RELEASE.*=.*:QMAKE_LFLAGS_RELEASE=${LDFLAGS}:" \
		-e "s:X11R6/::" \
		-i "${S}"/mkspecs/$(qt_mkspecs_dir)/qmake.conf || die "sed ${S}/mkspecs/$(qt_mkspecs_dir)/qmake.conf failed"

	sed -e "s:QMAKE_CFLAGS_RELEASE.*=.*:QMAKE_CFLAGS_RELEASE=${CFLAGS}:" \
		-e "s:QMAKE_CXXFLAGS_RELEASE.*=.*:QMAKE_CXXFLAGS_RELEASE=${CXXFLAGS}:" \
		-e "s:QMAKE_LFLAGS_RELEASE.*=.*:QMAKE_LFLAGS_RELEASE=${LDFLAGS}:" \
		-i "${S}"/mkspecs/common/g++.conf || die "sed ${S}/mkspecs/common/g++.conf failed"
}

qt4-build-edge_src_configure() {
	if ! use custom-cxxflags; then
		echo
		ewarn "You have set USE=custom-cxxflags, which means Qt will be built with the"
		ewarn "CXXFLAGS you have set in /etc/make.conf. This is not supported, and we"
		ewarn "recommend to unset this useflag. But you are free to experiment with it."
		ewarn "Just do not start crying if it breaks your system, or eats your kitten"
		ewarn "for breakfast. ;-) "
		echo
		strip-flags
		replace-flags -O3 -O2
	fi

	# hardened needs this, so it's needed in official tree still
#	if [[ $(gcc-fullversion) == "3.4.6" && gcc-specs-ssp ]] ; then
#		ewarn "Appending -fno-stack-protector to CFLAGS/CXXFLAGS"
#		append-flags -fno-stack-protector
#	fi

	myconf="$(standard_configure_options) ${myconf}"

	echo ./configure ${myconf}
	./configure ${myconf} || die "configure failed"
}

qt4-build-edge_src_compile() {
	build_directories "${QT4_TARGET_DIRECTORIES}"
}

qt4-build-edge_src_install() {
	install_directories "${QT4_TARGET_DIRECTORIES}"
	install_qconfigs
	fix_library_files
}

standard_configure_options() {
	local myconf=""

	[[ $(get_libdir) != "lib" ]] && myconf="${myconf} -L/usr/$(get_libdir)"

	# Disable visibility explicitly if gcc version isn't 4
#	if [[ "$(gcc-major-version)" -lt "4" ]]; then
#		myconf="${myconf} -no-reduce-exports"
#	fi

	# precompiled headers doesn't work on hardened, where the flag is masked.
	if use pch; then
		myconf="${myconf} -pch"
	else
		myconf="${myconf} -no-pch"
	fi

	if use debug; then
		myconf="${myconf} -debug -no-separate-debug-info"
	else
		myconf="${myconf} -release -no-separate-debug-info"
	fi

	# ARCH is set on Gentoo. Qt now falls back to generic on an unsupported
	# ${ARCH}. Therefore we convert it to supported values.
	case "${ARCH}" in
		amd64) myconf="${myconf} -arch x86_64" ;;
		ppc|ppc64) myconf="${myconf} -arch powerpc" ;;
		x86|x86-*) myconf="${myconf} -arch i386" ;;
		alpha|arm|ia64|mips|s390|sparc) myconf="${myconf} -arch ${ARCH}" ;;
		hppa|sh) myconf="${myconf} -arch generic" ;;
		*) die "${ARCH} is unsupported by this eclass. Please file a bug." ;;
	esac

	myconf="${myconf} -stl -verbose -largefile -confirm-license -no-rpath
		-prefix ${QTPREFIXDIR} -bindir ${QTBINDIR} -libdir ${QTLIBDIR}
		-datadir ${QTDATADIR} -docdir ${QTDOCDIR} -headerdir ${QTHEADERDIR}
		-plugindir ${QTPLUGINDIR} -sysconfdir ${QTSYSCONFDIR}
		-translationdir ${QTTRANSDIR} -examplesdir ${QTEXAMPLESDIR}
		-demosdir ${QTDEMOSDIR} -silent -fast -reduce-relocations
		-nomake examples -nomake demos"

	echo "${myconf}"
}

build_directories() {
	local dirs="$@"
	for x in ${dirs}; do
		cd "${S}"/${x}
		"${S}"/bin/qmake "LIBS+=-L${QTLIBDIR}" "CONFIG+=nostrip" || die "qmake failed"
		emake || die "emake failed"
	done
}

install_directories() {
	local dirs="$@"
	for x in ${dirs}; do
		pushd "${S}"/${x} >/dev/null || die "Can't pushd ${S}/${x}"
		emake INSTALL_ROOT="${D}" install || die "emake install failed"
		popd >/dev/null || die "Can't popd from ${S}/${x}"
	done
}

# @ECLASS-VARIABLE: QCONFIG_ADD
# @DESCRIPTION:
# List options that need to be added to QT_CONFIG in qconfig.pri
QCONFIG_ADD="${QCONFIG_ADD:-}"

# @ECLASS-VARIABLE: QCONFIG_REMOVE
# @DESCRIPTION:
# List options that need to be removed from QT_CONFIG in qconfig.pri
QCONFIG_REMOVE="${QCONFIG_REMOVE:-}"

# @ECLASS-VARIABLE: QCONFIG_DEFINE
# @DESCRIPTION:
# List variables that should be defined at the top of QtCore/qconfig.h
QCONFIG_DEFINE="${QCONFIG_DEFINE:-}"

install_qconfigs() {
	local x
	if [[ -n ${QCONFIG_ADD} || -n ${QCONFIG_REMOVE} ]]; then
		for x in QCONFIG_ADD QCONFIG_REMOVE; do
			[[ -n ${!x} ]] && echo ${x}=${!x} >> "${T}"/${PN}-qconfig.pri
		done
		insinto ${QTDATADIR}/mkspecs/gentoo
		doins "${T}"/${PN}-qconfig.pri || die "installing ${PN}-qconfig.pri failed"
	fi

	if [[ -n ${QCONFIG_DEFINE} ]]; then
		for x in ${QCONFIG_DEFINE}; do
			echo "#define ${x}" >> "${T}"/gentoo-${PN}-qconfig.h
		done
		insinto ${QTHEADERDIR}/Gentoo
		doins "${T}"/gentoo-${PN}-qconfig.h || die "installing ${PN}-qconfig.h failed"
	fi
}

generate_qconfigs() {
	if [[ -n ${QCONFIG_ADD} || -n ${QCONFIG_REMOVE} || -n ${QCONFIG_DEFINE} || ${CATEGORY}/${PN} == x11-libs/qt-core ]]; then
		local x qconfig_add qconfig_remove qconfig_new
		for x in "${ROOT}${QTDATADIR}"/mkspecs/gentoo/*-qconfig.pri; do
			[[ -f ${x} ]] || continue
			qconfig_add="${qconfig_add} $(sed -n 's/^QCONFIG_ADD=//p' "${x}")"
			qconfig_remove="${qconfig_remove} $(sed -n 's/^QCONFIG_REMOVE=//p' "${x}")"
		done

		# these error checks do not use die because dying in pkg_post{inst,rm}
		# just makes things worse.
		if [[ -e "${ROOT}${QTDATADIR}"/mkspecs/gentoo/qconfig.pri ]]; then
			# start with the qconfig.pri that qt-core installed
			if ! cp "${ROOT}${QTDATADIR}"/mkspecs/gentoo/qconfig.pri \
				"${ROOT}${QTDATADIR}"/mkspecs/qconfig.pri; then
				eerror "cp qconfig failed."
				return 1
			fi

			# generate list of QT_CONFIG entries from the existing list
			# including qconfig_add and excluding qconfig_remove
			for x in $(sed -n 's/^QT_CONFIG +=//p' \
				"${ROOT}${QTDATADIR}"/mkspecs/qconfig.pri) ${qconfig_add}; do
					hasq ${x} ${qconfig_remove} || qconfig_new="${qconfig_new} ${x}"
			done

			# replace the existing QT_CONFIG list with qconfig_new
			if ! sed -i -e "s/QT_CONFIG +=.*/QT_CONFIG += ${qconfig_new}/" \
				"${ROOT}${QTDATADIR}"/mkspecs/qconfig.pri; then
				eerror "Sed for QT_CONFIG failed"
				return 1
			fi

			# create Gentoo/qconfig.h
			if [[ ! -e ${ROOT}${QTHEADERDIR}/Gentoo ]]; then
				if ! mkdir -p "${ROOT}${QTHEADERDIR}"/Gentoo; then
					eerror "mkdir ${QTHEADERDIR}/Gentoo failed"
					return 1
				fi
			fi
			: > "${ROOT}${QTHEADERDIR}"/Gentoo/gentoo-qconfig.h
			for x in "${ROOT}${QTHEADERDIR}"/Gentoo/gentoo-*-qconfig.h; do
				[[ -f ${x} ]] || continue
				cat "${x}" >> "${ROOT}${QTHEADERDIR}"/Gentoo/gentoo-qconfig.h
			done
		else
			rm -f "${ROOT}${QTDATADIR}"/mkspecs/qconfig.pri
			rm -f "${ROOT}${QTHEADERDIR}"/Gentoo/gentoo-qconfig.h
			rmdir "${ROOT}${QTDATADIR}"/mkspecs \
				"${ROOT}${QTDATADIR}" \
				"${ROOT}${QTHEADERDIR}"/Gentoo \
				"${ROOT}${QTHEADERDIR}" 2>/dev/null
		fi
	fi
}

qt4-build-edge_pkg_postrm() {
	generate_qconfigs
}

qt4-build-edge_pkg_postinst() {
	generate_qconfigs
	echo
	ewarn "After a rebuild or upgrade of Qt, it can happen that Qt plugins (such as Qt"
	ewarn "and KDE styles and widgets) can no longer be loaded. In this situation you"
	ewarn "should recompile the packages providing these plugins. Also, make sure you"
	ewarn "compile the Qt packages, and the packages that depend on it, with the same"
	ewarn "GCC version and the same USE flag settings (especially the debug flag)."
	ewarn
	ewarn "Packages that typically need to be recompiled are kdelibs from KDE4, any"
	ewarn "additional KDE4/Qt4 styles, qscintilla and PyQt4. Before filing a bug report,"
	ewarn "make sure all your Qt4 packages are up-to-date and built with the same"
	ewarn "configuration."
	ewarn
	ewarn "For more information, see http://doc.trolltech.com/4.4/plugins-howto.html"
	echo
}

skip_qmake_build_patch() {
	# Don't need to build qmake, as it's already installed from qt-core
	sed -i -e "s:if true:if false:g" "${S}"/configure || die "Sed failed"
}

skip_project_generation_patch() {
	# Exit the script early by throwing in an exit before all of the .pro files are scanned
	sed -e "s:echo \"Finding:exit 0\n\necho \"Finding:g" \
		-i "${S}"/configure || die "Sed failed"
}

symlink_binaries_to_buildtree() {
	for bin in qmake moc uic rcc; do
		ln -s ${QTBINDIR}/${bin} "${S}"/bin/ || die "Symlinking ${bin} to ${S}/bin failed."
	done
}

fix_library_files() {
	for libfile in "${D}"/${QTLIBDIR}/{*.la,*.prl,pkgconfig/*.pc}; do
		if [[ -e ${libfile} ]]; then
			sed -i -e "s:${S}/lib:${QTLIBDIR}:g" ${libfile} || die "Sed on ${libfile} failed."
		fi
	done

	# pkgconfig files refer to WORKDIR/bin as the moc and uic locations.  Fix:
	for libfile in "${D}"/${QTLIBDIR}/pkgconfig/*.pc; do
		if [[ -e ${libfile} ]]; then
			sed -i -e "s:${S}/bin:${QTBINDIR}:g" ${libfile} || die "Sed failed"

	# Move .pc files into the pkgconfig directory

		dodir ${QTPCDIR}
		mv ${libfile} "${D}"/${QTPCDIR}/ \
			|| die "Moving ${libfile} to ${D}/${QTPCDIR}/ failed."
		fi
	done

	# Don't install an empty directory
	rmdir "${D}"/${QTLIBDIR}/pkgconfig
}

qt_use() {
	local flag="${1}"
	local feature="${1}"
	local enableval=

	[[ -n ${2} ]] && feature=${2}
	[[ -n ${3} ]] && enableval="-${3}"

	if use ${flag}; then
		echo "${enableval}-${feature}"
	else
		echo "-no-${feature}"
	fi
}

qt_mkspecs_dir() {
	# Allows us to define which mkspecs dir we want to use.
	local spec

	case ${CHOST} in
		*-freebsd*|*-dragonfly*)
			spec="freebsd" ;;
		*-openbsd*)
			spec="openbsd" ;;
		*-netbsd*)
			spec="netbsd" ;;
		*-darwin*)
			spec="darwin" ;;
		*-linux-*|*-linux)
			spec="linux" ;;
		*)
			die "Unknown CHOST, no platform choosen."
	esac

	CXX=$(tc-getCXX)
	if [[ ${CXX/g++/} != ${CXX} ]]; then
		spec="${spec}-g++"
	elif [[ ${CXX/icpc/} != ${CXX} ]]; then
		spec="${spec}-icc"
	else
		die "Unknown compiler ${CXX}."
	fi

	echo "${spec}"
}

EXPORT_FUNCTIONS pkg_setup src_unpack src_prepare src_configure src_compile src_install pkg_postrm pkg_postinst
