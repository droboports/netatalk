#CFLAGS="${CFLAGS:-} -ffunction-sections -fdata-sections"
#LDFLAGS="-L${DEST}/lib -L${DEPS}/lib -Wl,--gc-sections"
LDFLAGS="-L${DEST}/lib -L${DEPS}/lib"

### ZLIB ###
_build_zlib() {
# Closest to the one that ships with the 5N (v1.2.3.4)
local VERSION="1.2.3"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://downloads.sourceforge.net/project/libpng/zlib/${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --shared
make
make install
popd
}

### OPENSSL ###
_build_openssl() {
# Same as the one that ships with the 5N
local OPENSSL_VERSION="0.9.8n"
local OPENSSL_FOLDER="openssl-${OPENSSL_VERSION}"
local OPENSSL_FILE="${OPENSSL_FOLDER}.tar.gz"
local OPENSSL_URL="https://www.openssl.org/source/old/0.9.x/${OPENSSL_FILE}"

_download_tgz "${OPENSSL_FILE}" "${OPENSSL_URL}" "${OPENSSL_FOLDER}"
pushd target/"${OPENSSL_FOLDER}"
./Configure --prefix="${DEPS}" shared threads linux-generic32 \
  zlib-dynamic --with-zlib-include="${DEPS}/include" --with-zlib-lib="${DEPS}/lib" \
  -DL_ENDIAN ${CFLAGS} ${LDFLAGS}
sed -e "s/-O3//g" -i Makefile
make -j1
make install_sw
popd
}

### BDB ###
_build_bdb() {
# Same as the one that ships with the 5N
local VERSION="5.2.42"
local FOLDER="db-${VERSION}"
local FILE="${FOLDER}.gz"
local URL="http://download.oracle.com/otn/berkeley-db/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}/build_unix"
../dist/configure --host="${HOST}" --prefix="${DEPS}" --enable-shared --disable-static
make
make install
popd
}

### LIBGPG-ERROR ###
_build_libgpg_error() {
# Same as the one that ships with the 5N
local VERSION="1.10"
local FOLDER="libgpg-error-${VERSION}"
local FILE="${FOLDER}.tar.bz2"
local URL="ftp://ftp.gnupg.org/gcrypt/libgpg-error/${FILE}"

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --enable-shared --disable-static --enable-threads=posix --disable-doc
make -j1
make install
popd
}

### LIBGCRYPT ###
_build_libgcrypt() {
# Same as the one that ships with the 5N
local VERSION="1.5.0"
local FOLDER="libgcrypt-${VERSION}"
local FILE="${FOLDER}.tar.bz2"
local URL="ftp://ftp.gnupg.org/gcrypt/libgcrypt/${FILE}"

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --enable-shared --disable-static --with-gpg-error-prefix="${DEPS}"
make
make install
popd
}

### NETATALK ###
_build_netatalk() {
local VERSION="3.1.7"
local FOLDER="netatalk-${VERSION}"
local FILE="${FOLDER}.tar.bz2"
local URL="http://sourceforge.net/projects/netatalk/files/netatalk/${VERSION}/${FILE}"

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
# See: http://sourceforge.net/p/netatalk/bugs/574/
sed -i '64i#define O_IGNORE 0' "include/atalk/acl.h"
./configure --host="${HOST}" --prefix="" --localstatedir="/mnt/DroboFS/System" --with-uams-path="/lib/netatalk" --enable-shared --disable-static --with-shadow --without-pam --with-libgcrypt-dir="${DEPS}" --with-ssl-dir="${DEPS}" --with-bdb="${DEPS}"
make
make install DESTDIR="${DEST}"
"${STRIP}" -s -R .comment -R .note -R .note.ABI-tag "${DEST}/sbin/"* "${DEST}/bin/"* || true
popd
}

_build() {
  _build_zlib
  _build_openssl
  _build_bdb
  _build_libgpg_error
  _build_libgcrypt
  _build_netatalk
  _package
}
