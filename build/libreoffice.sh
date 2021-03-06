#!/usr/bin/env bash

# The current LibreOffice version
VERSION="5.2.7"

AWS_BASE_URL=https://s3.amazonaws.com/static.hubstaff.com/heroku_libreoffice_buildpack/source

# Official download for .debs
#DEB_DOWNLOAD_URL="http://download.documentfoundation.org/libreoffice/stable/${VERSION}/deb/x86_64/LibreOffice_${VERSION}_Linux_x86-64_deb.tar.gz"
#GETTEXT_DOWNLOAD_URL="http://ftp.gnu.org/pub/gnu/gettext/gettext-0.18.3.1.tar.gz"
#DBUS_DOWNLOAD_URL="http://dbus.freedesktop.org/releases/dbus/dbus-1.6.18.tar.gz"
#LIBFFI_DOWNLOAD_URL="ftp://sourceware.org/pub/libffi/libffi-3.0.13.tar.gz"
#GLIB_DOWNLOAD_URL="http://ftp.gnome.org/pub/gnome/sources/glib/2.38/glib-2.38.2.tar.xz"
#DBUS_GLIB_DOWNLOAD_URL="http://dbus.freedesktop.org/releases/dbus-glib/dbus-glib-0.100.2.tar.gz"
#FLEX_DOWNLOAD_URL="http://sourceforge.net/projects/flex/files/flex-2.5.39.tar.xz/download"
#MESA_DOWNLOAD_URL="ftp://ftp.freedesktop.org/pub/mesa/older-versions/11.x/11.0.9/mesa-11.0.9.tar.xz"
#GLU_DOWNLOAD_URL="ftp://ftp.freedesktop.org/pub/mesa/glu/glu-9.0.0.tar.gz"
#POPPLER_DOWNLOAD_URL="https://poppler.freedesktop.org/poppler-0.51.0.tar.xz"
#POPPLER_DOWNLOAD_URL="https://github.com/NetsoftHoldings/poppler/archive/netsoft-0.56.1.tar.gz"
#OPENJPEG_DOWNLOAD_URL="https://github.com/uclouvain/openjpeg/archive/v2.1.2.tar.gz"
#CMAKE_DOWNLOAD_URL="https://cmake.org/files/v3.9/cmake-3.9.0-Linux-x86_64.tar.gz"


DEB_DOWNLOAD_URL=$AWS_BASE_URL/LibreOffice_${VERSION}_Linux_x86-64_deb.tar.gz
GETTEXT_DOWNLOAD_URL="$AWS_BASE_URL/gettext-0.18.3.1.tar.gz"
DBUS_DOWNLOAD_URL="$AWS_BASE_URL/dbus-1.6.18.tar.gz"
LIBFFI_DOWNLOAD_URL="$AWS_BASE_URL/libffi-3.0.13.tar.gz"
GLIB_DOWNLOAD_URL="$AWS_BASE_URL/glib-2.38.2.tar.xz"
DBUS_GLIB_DOWNLOAD_URL="$AWS_BASE_URL/dbus-glib-0.100.2.tar.gz"
FLEX_DOWNLOAD_URL="$AWS_BASE_URL/flex-2.5.39.tar.xz"
MESA_DOWNLOAD_URL="$AWS_BASE_URL/mesa-11.0.9.tar.xz"
GLU_DOWNLOAD_URL="$AWS_BASE_URL/glu-9.0.0.tar.gz"
OPENJPEG_DOWNLOAD_URL="$AWS_BASE_URL/openjpeg-v2.1.2.tar.gz"
POPPLER_DOWNLOAD_URL="https://github.com/NetsoftHoldings/poppler/archive/netsoft-0.56.1.tar.gz"
CMAKE_DOWNLOAD_URL="$AWS_BASE_URL/cmake-3.9.0-Linux-x86_64.tar.gz"


# File names
LIBREOFFICE_BINARIES_FILE="libreoffice${VERSION}_x86-64.tar.gz"
DEPS_FILE="libreoffice${VERSION}_x86-64_deps.tar.gz"

MAKE_OPTS=-j4
PREFIX=/app/vendor/libreoffice/deps
mkdir -p $PREFIX

temp_dir=$(mktemp -d /tmp/libreoffice.XXXXXXXXXX)
cd ${temp_dir}

# Release dir
mkdir -p release

# Download and extract the .debs
curl -L ${DEB_DOWNLOAD_URL} -o libreoffice.tar.gz
archive_name=$(tar tzf libreoffice.tar.gz | sed -e 's@/.*@@' | uniq)
tar xzf libreoffice.tar.gz

cd ${archive_name}

needed_debs="\
	DEBS/libobasis5.2-core_* \
	DEBS/libobasis5.2-en-us_* \
	DEBS/libobasis5.2-en-us-res_* \
	DEBS/libobasis5.2-en-us-writer_* \
	DEBS/libobasis5.2-graphicfilter_* \
	DEBS/libobasis5.2-writer_* \
	DEBS/libobasis5.2-ooofonts_* \
	DEBS/libreoffice5.2_* \
	DEBS/libreoffice5.2-ure_* \
	DEBS/libreoffice5.2-writer_* \
	"

for f in $needed_debs
do
  ar p "$f" data.tar.gz | tar zx
done

tar pczf ${LIBREOFFICE_BINARIES_FILE} opt
mv ${LIBREOFFICE_BINARIES_FILE} "${temp_dir}/release/${LIBREOFFICE_BINARIES_FILE}"
cd ${temp_dir}

echo "==================================== LibreOffice built, now building dependencies ===================================="

# ============================== DEPENDENCIES ======================================

# Download and build gettext
curl -L ${GETTEXT_DOWNLOAD_URL} -o gettext.tar.gz
archive_name=$(tar tzf gettext.tar.gz | sed -e 's@/.*@@' | uniq)
tar xzf gettext.tar.gz
cd ${archive_name}
./configure --prefix=${PREFIX}
make ${MAKE_OPTS}
make install
cd ${temp_dir}

# Add gettext to PATH and LD_LIBRARY_PATH and PKG_CONFIG_PATH
export PATH="$PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"

# Download and build DBus
curl -L ${DBUS_DOWNLOAD_URL} -o dbus.tar.gz
archive_name=$(tar tzf dbus.tar.gz | sed -e 's@/.*@@' | uniq)
tar xzf dbus.tar.gz
cd ${archive_name}
./configure --prefix=${PREFIX}
make ${MAKE_OPTS}
make install -k
cd ${temp_dir}

# Download and build libffi
curl -L ${LIBFFI_DOWNLOAD_URL} -o libffi.tar.gz
archive_name=$(tar tzf libffi.tar.gz | sed -e 's@/.*@@' | uniq)
tar xzf libffi.tar.gz
cd ${archive_name}
./configure --prefix=${PREFIX}
make ${MAKE_OPTS}
make install
cd ${temp_dir}

# Download and build GLib
curl -L ${GLIB_DOWNLOAD_URL} -o glib.tar.xz
archive_name=$(tar tJf glib.tar.xz | sed -e 's@/.*@@' | uniq)
tar xJf glib.tar.xz
cd ${archive_name}
./configure --prefix=${PREFIX}
make ${MAKE_OPTS}
make install
cd ${temp_dir}

# Download and build DBus-GLib
curl -L ${DBUS_GLIB_DOWNLOAD_URL} -o dbus-glib.tar.gz
archive_name=$(tar tzf dbus-glib.tar.gz | sed -e 's@/.*@@' | uniq)
tar xzf dbus-glib.tar.gz
cd ${archive_name}
./configure --prefix=${PREFIX}
make ${MAKE_OPTS}
make install
cd ${temp_dir}

# Download and build flex
curl -L ${FLEX_DOWNLOAD_URL} -o flex.tar.xz
archive_name=$(tar tJf flex.tar.xz | sed -e 's@/.*@@' | uniq)
tar xJf flex.tar.xz
cd ${archive_name}
./configure --prefix=${PREFIX}
make ${MAKE_OPTS}
make install
cd ${temp_dir}

# Download and install cmake
curl -L ${CMAKE_DOWNLOAD_URL} -o cmake.tar.gz
archive_name=$(tar tzf cmake.tar.gz | sed -e 's@/.*@@' | uniq)
tar xzf cmake.tar.gz
export CMAKE=$PWD/${archive_name}/bin/cmake

# Download and build openjpeg
curl -L ${OPENJPEG_DOWNLOAD_URL} -o openjpeg.tar.gz
archive_name=$(tar tzf openjpeg.tar.gz | sed -e 's@/.*@@' | uniq)
tar xzf openjpeg.tar.gz
cd ${archive_name}
mkdir build
cd build
$CMAKE .. -DCMAKE_INSTALL_PREFIX=$PREFIX
make ${MAKE_OPTS}
make install
cd ${temp_dir}

# Download and build poppler
curl -L ${POPPLER_DOWNLOAD_URL} -o poppler.tar.gz
archive_name=$(tar tzf poppler.tar.gz | sed -e 's@/.*@@' | uniq)
tar xzf poppler.tar.gz
cd ${archive_name}
mkdir build
cd build
$CMAKE .. -DCMAKE_INSTALL_PREFIX=$PREFIX \
	-DCMAKE_EXE_LINKER_FLAGS=-L$PREFIX/lib \
	-DCMAKE_SHARED_LINKER_FLAGS=-L$PREFIX/lib \
	-DCMAKE_SKIP_BUILD_RPATH=TRUE \
	-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
	-DCMAKE_INSTALL_RPATH="\$ORIGIN/../lib"
make ${MAKE_OPTS}
make install
cd ${temp_dir}

# Download and build Mesa
curl -L ${MESA_DOWNLOAD_URL} -o mesa.tar.xz
archive_name=$(tar tJf mesa.tar.xz | sed -e 's@/.*@@' | uniq)
tar xJf mesa.tar.xz
cd ${archive_name}
./configure --prefix=${PREFIX} --with-gallium-drivers=swrast --disable-dri3 --disable-dri \
            --disable-egl --enable-gallium-osmesa --with-osmesa-lib-name=GL --enable-glx-tls
make ${MAKE_OPTS}
make install
cd ${temp_dir}

# Download and build GLU
curl -L ${GLU_DOWNLOAD_URL} -o glu.tar.gz
archive_name=$(tar tzf glu.tar.gz | sed -e 's@/.*@@' | uniq)
tar xzf glu.tar.gz
cd ${archive_name}
./configure --prefix=${PREFIX}
make ${MAKE_OPTS}
make install
cd ${temp_dir}

echo "Removing dependency files"
# Only removing files that we are sure we won't need and are worth removing
# eg. saving megabytes and are only needed when compiling or other interactive usage
rm -rf ${PREFIX}/lib/*.a
rm -rf ${PREFIX}/lib/*.la
rm -rf ${PREFIX}/share/gtk-doc
rm -rf ${PREFIX}/share/locale
rm -rf ${PREFIX}/share/doc
rm -rf ${PREFIX}/share/info
rm -rf ${PREFIX}/include
mkdir ${PREFIX}/bin-good
POPPLER_BINS="pdftotext pdftoppm pdftohtml pdftocairo pdfunite pdfseparate"
for x in $POPPLER_BINS; do
    cp ${PREFIX}/bin/$x ${PREFIX}/bin-good/$x
done
rm -rf ${PREFIX}/bin
mv ${PREFIX}/bin-good ${PREFIX}/bin

# Compress all dependencies
tar pczf ${DEPS_FILE} ${PREFIX}
mv ${DEPS_FILE} release/${DEPS_FILE}

echo "=================================== DONE ( $temp_dir ) ================================"
