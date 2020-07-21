#
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# local automake definitions for ntop
## (this file is processed with 'automake' to produce Makefile.in)
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#
# Copyright (c) 1998, 2000 Luca Deri <deri@ntop.org>
# Updated 1Q 2000 Rocco Carbone <rocco@ntop.org>
#
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#

dnl>
dnl>  Check for an ANSI C typedef in a header
dnl>
dnl>  configure.in:
dnl>    AC_CHECK_TYPEDEF(<typedef>, <header>)
dnl>  acconfig.h:
dnl>    #undef HAVE_<typedef>
dnl>

AC_DEFUN([AC_CHECK_TYPEDEF],[dnl
AC_REQUIRE([AC_HEADER_STDC])dnl
AC_MSG_CHECKING(for typedef $1)
AC_CACHE_VAL(ac_cv_typedef_$1,
[AC_EGREP_CPP(dnl
changequote(<<,>>)dnl
<<(^|[^a-zA-Z_0-9])$1[^a-zA-Z_0-9]>>dnl
changequote([,]), [
#include <$2>
], ac_cv_typedef_$1=yes, ac_cv_typedef_$1=no)])dnl
AC_MSG_RESULT($ac_cv_typedef_$1)
if test $ac_cv_typedef_$1 = yes; then
    AC_DEFINE(HAVE_[]translit($1, [a-z], [A-Z]))
fi
])


dnl>
dnl>  Check whether compiler option works
dnl>
dnl>  configure.in:
dnl>    AC_COMPILER_OPTION(<name>, <display>, <option>,
dnl>                       <action-success>, <action-failure>)
dnl>

AC_DEFUN([AC_COMPILER_OPTION],[dnl
AC_MSG_CHECKING(for compiler option $2)
AC_CACHE_VAL(ac_cv_compiler_option_$1,[
cat >conftest.$ac_ext <<EOF
int main() { return 0; }
EOF
${CC-cc} -c $CFLAGS $CPPFLAGS $3 conftest.$ac_ext 1>conftest.out 2>conftest.err
if test $? -ne 0 -o -s conftest.err; then
     ac_cv_compiler_option_$1=no
else
     ac_cv_compiler_option_$1=yes
fi
rm -f conftest.$ac_ext conftest.out conftest.err
])dnl
if test ".$ac_cv_compiler_option_$1" = .yes; then
    ifelse([$4], , :, [$4])
else
    ifelse([$5], , :, [$5])
fi
AC_MSG_RESULT([$ac_cv_compiler_option_$1])
])dnl


dnl>
dnl>  Debugging Support
dnl>
dnl>  configure.in:
dnl>    AC_CHECK_DEBUGGING
dnl>

AC_DEFUN([AC_CHECK_DEBUGGING],[dnl
AC_ARG_ENABLE(debug,dnl
[  --enable-debug          build for debugging (default=no)],
[dnl
if test ".$ac_cv_prog_gcc" = ".yes"; then
    case "$CFLAGS" in
        *-O* ) ;;
           * ) CFLAGS="$CFLAGS -O2" ;;
    esac
    case "$CFLAGS" in
        *-g* ) ;;
           * ) CFLAGS="$CFLAGS -g" ;;
    esac
    case "$CFLAGS" in
        *-pipe* ) ;;
              * ) AC_COMPILER_OPTION(pipe, -pipe, -pipe, CFLAGS="$CFLAGS -pipe") ;;
    esac
    AC_COMPILER_OPTION(ggdb3, -ggdb3, -ggdb3, CFLAGS="$CFLAGS -ggdb3")
    case $PLATFORM in
        *-*-freebsd*|*-*-solaris* ) CFLAGS="$CFLAGS -pedantic" ;;
    esac
    CFLAGS="$CFLAGS -Wall"
    WMORE="-Wshadow -Wpointer-arith -Wcast-align -Winline"
    WMORE="$WMORE -Wmissing-prototypes -Wmissing-declarations -Wnested-externs"
    AC_COMPILER_OPTION(wmore, -W<xxx>, $WMORE, CFLAGS="$CFLAGS $WMORE")
else
    case "$CFLAGS" in
        *-g* ) ;;
           * ) CFLAGS="$CFLAGS -g" ;;
    esac
fi
msg="enabled"
AC_DEFINE(DEBUG)
],[
if test ".$ac_cv_prog_gcc" = ".yes"; then
case "$CFLAGS" in
    *-pipe* ) ;;
          * ) AC_COMPILER_OPTION(pipe, -pipe, -pipe, CFLAGS="$CFLAGS -pipe") ;;
esac
fi
case "$CFLAGS" in
    *-g* ) CFLAGS=`echo "$CFLAGS" |\
                   sed -e 's/ -g / /g' -e 's/ -g$//' -e 's/^-g //g' -e 's/^-g$//'` ;;
esac
case "$CXXFLAGS" in
    *-g* ) CXXFLAGS=`echo "$CXXFLAGS" |\
                     sed -e 's/ -g / /g' -e 's/ -g$//' -e 's/^-g //g' -e 's/^-g$//'` ;;
esac
msg="disabled"
])dnl
AC_MSG_CHECKING(for compilation debug mode)
AC_MSG_RESULT([$msg])
if test ".$msg" = .enabled; then
    enable_shared=no
fi
])

dnl>
dnl>  Optimization Support
dnl>
dnl>  configure.in:
dnl>    AC_CHECK_OPTIMIZE
dnl>

AC_DEFUN([AC_CHECK_OPTIMIZE],[dnl
AC_ARG_ENABLE(optimize,dnl
[  --enable-optimize       build with optimization (default=no)],
[dnl
if test ".$ac_cv_prog_gcc" = ".yes"; then
    #  compiler is gcc
    case "$CFLAGS" in
        *-O* ) ;;
        * ) CFLAGS="$CFLAGS -O2" ;;
    esac
    case "$CFLAGS" in
        *-pipe* ) ;;
        * ) AC_COMPILER_OPTION(pipe, -pipe, -pipe, CFLAGS="$CFLAGS -pipe") ;;
    esac
    OPT_CFLAGS='-funroll-loops -fstrength-reduce -fomit-frame-pointer -ffast-math'
    AC_COMPILER_OPTION(optimize_std, [-f<xxx> for optimizations], $OPT_CFLAGS, CFLAGS="$CFLAGS $OPT_CFLAGS")
    case $PLATFORM in
        i?86*-*-*|?86*-*-* )
            OPT_CFLAGS='-malign-functions=4 -malign-jumps=4 -malign-loops=4'
            AC_COMPILER_OPTION(optimize_x86, [-f<xxx> for Intel x86 CPU], $OPT_CFLAGS, CFLAGS="$CFLAGS $OPT_CFLAGS")
            ;;
    esac
else
    #  compiler is NOT gcc
    case "$CFLAGS" in
        *-O* ) ;;
           * ) CFLAGS="$CFLAGS -O" ;;
    esac
    case $PLATFORM in
        *-*-solaris* )
            AC_COMPILER_OPTION(fast, -fast, -fast, CFLAGS="$CFLAGS -fast")
            ;;
    esac
fi
msg="enabled"
],[
msg="disabled"
])dnl
AC_MSG_CHECKING(for compilation optimization mode)
AC_MSG_RESULT([$msg])
])

#
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# local automake definitions for ntop
## (this file is processed with 'automake' to produce Makefile.in)
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#
# Copyright (c) 1998-2003 Luca Deri <deri@ntop.org>
# Updated 1Q 2000 Rocco Carbone <rocco@ntop.org>
# Rewrite 1Q 2003 Burton M. Strauss III <burton@ntopsupport.com>
#
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#

dnl>
dnl>  Check for an ANSI C typedef in a header
dnl>
dnl>  configure.in:
dnl>    AC_CHECK_TYPEDEF(<typedef>, <header>)
dnl>  acconfig.h:
dnl>    #undef HAVE_<typedef>
dnl>

AC_DEFUN([AC_CHECK_TYPEDEF],[dnl
AC_REQUIRE([AC_HEADER_STDC])dnl
AC_MSG_CHECKING(for typedef $1)
AC_CACHE_VAL(ac_cv_typedef_$1,
[AC_EGREP_CPP(dnl
changequote(<<,>>)dnl
<<(^|[^a-zA-Z_0-9])$1[^a-zA-Z_0-9]>>dnl
changequote([,]), [
#include <$2>
], ac_cv_typedef_$1=yes, ac_cv_typedef_$1=no)])dnl
AC_MSG_RESULT($ac_cv_typedef_$1)
if test $ac_cv_typedef_$1 = yes; then
    AC_DEFINE(HAVE_[]translit($1, [a-z], [A-Z]))
fi
])

dnl>
dnl>  Appends values to $CPPFLAGS, $LDFLAGS and $LIBS
dnl>         Also: Allows us to automate for those OSes which DO NOT check subdirectories.
dnl>               Allows us to strip dups.
dnl>

# NTOP_APPENDS(Ivalue, Lvalue, lvalue)
# ----------------------------------------------
AC_DEFUN([NTOP_APPENDS],
[dnl
# Expansion of NTOP_APPENDS($1, $2, $3)
    if test ".$1" != "."; then
        rc=`(echo $CPPFLAGS | grep '$1 ' > /dev/null 2> /dev/null; echo $?)`
        if [[ $rc -eq 1 ]]; then
           CPPFLAGS="$CPPFLAGS -I$1"
        fi
        rc=`(echo $INCS | grep '$1' > /dev/null 2> /dev/null; echo $?)`
        if [[ $rc -eq 1 ]]; then
            INCS="$INCS -I$1"
        fi
    fi
    if test ".$2" != "."; then
        rc=`(echo $LDFLAGS | grep '$2 ' > /dev/null 2> /dev/null; echo $?)`
        if [[ $rc -eq 1 ]]; then
            case "${DEFINEOS}" in
              DARWIN )
                LDFLAGS="$LDFLAGS -L$2 -L$2/lib"
                ;;
              * )
                LDFLAGS="$LDFLAGS -L$2"
                ;;
            esac
        fi
    fi
    if test ".$3" != "."; then
        rc=`(echo $LIBS | grep '\-l$3 ' > /dev/null 2> /dev/null; echo $?)`
        if [[ $rc -eq 1 ]]; then
            LIBS="$LIBS -l$3"
        fi
    fi
# Finished expansion of NTOP_APPENDS()
])

dnl>
dnl>  Report location
dnl>

# NTOP_RPT_LOC(item, lib, include)
# ----------------------------------------------
AC_DEFUN([NTOP_RPT_LOC],
[dnl
# Expansion of NTOP_RPT_LOC($1 $2 $3)
if test ".$3" = "."; then
    echo "$1 .h             : standard system headers"
else
    echo "$1 .h             : $3"
fi
if test ".$2" = "."; then
    echo "$1 library        : standard system libraries"
else
    echo "$1 library        : $2"
fi
# Finished expansion of NTOP_RPT_LOC()
])

# NTOP_SET_LIBINC(item)
# ----------------------------------------------
AC_DEFUN([NTOP_SET_LIBINC],
[dnl
# Expansion of NTOP_SET_LIBINC($1)
if test ".${$1_DIRECTORY}" != "."; then
    if test ".${$1_LIB}" = "."; then
        if test -d ${$1_DIRECTORY}/lib; then
            $1_LIB="${$1_DIRECTORY}/lib"
        else
            $1_LIB="${$1_DIRECTORY}"
        fi
    fi
    if test ".${$1_INCLUDE}" = "."; then
        if test -d ${$1_DIRECTORY}/include; then
            $1_INCLUDE="${$1_DIRECTORY}/include"
        else
            $1_INCLUDE="${$1_DIRECTORY}"
        fi
    fi
fi
# Finished expansion of NTOP_SET_LIBINC()
])

# NTOP_SUGGESTION(item, version)
# ----------------------------------------------
AC_DEFUN([NTOP_SUGGESTION],
[dnl
# Expansion of NTOP_SUGGESTION($1, $2, $3)
    echo "*???    Suggestion - Install a private copy of $1 $2."
    echo "*???                 It's quite easy and does NOT require root:"
    echo "*"
    echo "*   Download $1 $2 from gnu"
    echo "*     \$ wget http://ftp.gnu.org/gnu/$1/$1-$2.tar.gz"
    echo "*"
    echo "*   Untar it"
    echo "*     \$ tar xfvz $1-$2.tar.gz"
    echo "*"
    echo "*   Make it"
    echo "*     \$ cd $1-$2"
    echo "*     \$ ./configure --prefix=/home/<whatever>/$1$3"
    echo "*     \$ make"
    echo "*     \$ make install"
    echo "*"
    echo "*   Add it to your path.  Under bash do this:"
    echo "*     \$ PATH=/home/<whatever>/$1$3/bin:\$PATH"
    echo "*     \$ export PATH"
    echo "*"
# Finished expansion of NTOP_SUGGESTION()
])

# NTOPCONFIGDEBUG_SETTINGS(where)
# ----------------------------------------------
AC_DEFUN([NTOPCONFIGDEBUG_SETTINGS],
[dnl
# Expansion of NTOPCONFIGDEBUG_SETTINGS()
if test ".${NTOPCONFIGDEBUG}" = ".yes"; then
    echo "DEBUG: $1"
    echo "       AWK.................'${AWK}'"
    echo "       AS..................'${AS}'"
    echo "       ACLOCAL.............'${ACLOCAL}'"
    echo "       AUTOCONF............'${AUTOCONF}'"
    echo "       AUTOHEADER..........'${AUTOHEADER}'"
    echo "       AUTOMAKE............'${AUTOMAKE}'"
    echo "       CC..................'${CC}'"
    echo "          gcc?.............'${GCC}'"
    echo "       CCLD................'${CCLD}'"
    echo "       CFLAGS..............'${CFLAGS}'"
    echo "       CPP.................'${CPP}'"
    echo "       CPPFLAGS............'${CPPFLAGS}'"
    echo "       DEFS................'${DEFS}'"
    echo "       DEPDIR..............'${DEPDIR}'"
    echo "       DLLTOOL.............'${DLLTOOL}'"
    echo "       DYN_FLAGS...........'${DYNFLAGS}'"
    echo "       EXEEXT..............'${EXEEXT}'"
    echo "       INCS................'${INCS}'"
    echo "       LDFLAGS.............'${LDFLAGS}'"
    echo "       LIBS................'${LIBS}'"
    echo "       LN_S................'${LN_S}'"
    echo "       MYRRD...............'${MYRRD}'"
    echo "       OBJDUMP.............'${OBJDUMP}'"
    echo "       OBJEXT..............'${OBJEXT}'"
    echo "       RANLIB..............'${RANLIB}'"
    echo "       SO_VERSION_PATCH....'${SO_VERSION_PATCH}'"
    echo "       build...............'${build}'"
    echo "       host................'${host}'"
    echo "       target..............'${target}'"
fi
# Finished expansion of NTOPCONFIGDEBUG_SETTINGS()
])
