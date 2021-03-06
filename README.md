# Welcome to the qt overlay!

[![Repoman Status](https://travis-ci.org/gentoo/qt.png)](https://travis-ci.org/gentoo/qt)

This is where the Gentoo Qt team develops and maintains ebuilds for
experimental Qt versions (pre-releases and "live" code from git) and
Qt-related packages. For your convenience we provide some sets and
`package.keyword` files.

The overlay is hosted on Github and on the official Gentoo infrastructure at:

- https://github.com/gentoo/qt
- https://gitweb.gentoo.org/proj/qt.git

You don't need to emerge the Qt ebuilds specifically, they are normally pulled
in as dependencies for packages that use Qt. But you may want to have all of
Qt installed, for example if you are a developer or tester. In that case we
recommend you copy the most applicable set to your `/etc/portage/sets/`
directory, rename it (to prevent portage error on set redefinition), and
customize it to your own wishes.

KDE users should note that at this point they need to use the
`media-libs/phonon` package instead of `dev-qt/qtphonon`. This is the reason
why `dev-qt/qtphonon` is commented out in the `qt4` set.

If you have questions, you can find us on IRC in #gentoo-qt on Freenode or at
[qt@gentoo.org](mailto:qt@gentoo.org).

Bugs should be reported on https://bugs.gentoo.org. Be sure to include
"[qt overlay]" in the summary of your bug report.

Users wanting to contribute should first read the
[Qt4 ebuild guide](http://www.gentoo.org/proj/en/desktop/qt/qt4-based-ebuild-howto.xml).
