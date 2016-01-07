# Don't use these:
#CFLAGS="${CFLAGS:-} -ffunction-sections -fdata-sections"
#LDFLAGS="-L${DEST}/lib -L${DEPS}/lib -Wl,--gc-sections"
# Use only this:
LDFLAGS="-L${DEST}/lib -L${DEPS}/lib"

### ZLIB ###
_build_zlib() {
local VERSION="1.2.8"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}"
make
make install
rm -vf "${DEPS}/lib/libz.so"*
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.0.2e"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://mirror.switch.ch/ftp/mirror/openssl/source/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-parallel-build.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 -i "${FOLDER}-parallel-build.patch"
./Configure --prefix="${DEPS}" \
  zlib-dynamic --with-zlib-include="${DEPS}/include" --with-zlib-lib="${DEPS}/lib" \
  no-shared threads linux-armv4 no-ssl2 no-ssl3 -DL_ENDIAN ${CFLAGS} ${LDFLAGS} \
  -Wa,--noexecstack -Wl,-z,noexecstack
sed -i -e "s/-O3//g" Makefile
make
make install_sw
rm -vf "${DEPS}/lib/libcrypto.so"* "${DEPS}/lib/libssl.so"*
popd
}

### BDB ###
_build_bdb() {
local VERSION="6.1.26"
local FOLDER="db-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://download.oracle.com/berkeley-db/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}/build_unix"
../dist/configure --host="${HOST}" --prefix="${DEPS}" --disable-shared
make
make install
popd
}

### LIBGPG-ERROR ###
_build_libgpg_error() {
local VERSION="1.21"
local FOLDER="libgpg-error-${VERSION}"
local FILE="${FOLDER}.tar.bz2"
local URL="ftp://ftp.gnupg.org/gcrypt/libgpg-error/${FILE}"

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
ln -fs lock-obj-pub.arm-unknown-linux-gnueabi.h src/syscfg/lock-obj-pub.linux-gnueabi.h
./configure --host="${HOST}" --prefix="${DEPS}" --disable-shared --enable-threads=posix --disable-doc
make
make install
popd
}

### LIBGCRYPT ###
_build_libgcrypt() {
local VERSION="1.6.4"
local FOLDER="libgcrypt-${VERSION}"
local FILE="${FOLDER}.tar.bz2"
local URL="ftp://ftp.gnupg.org/gcrypt/libgcrypt/${FILE}"

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --disable-shared --with-gpg-error-prefix="${DEPS}"
make
make install
popd
}

### LIBATTR ###
_build_libattr() {
local VERSION="2.4.47"
local FOLDER="attr-${VERSION}"
local FILE="${FOLDER}.src.tar.gz"
local URL="http://download.savannah.gnu.org/releases/attr/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --disable-shared
make
make install install-dev install-lib
popd
}

### NETATALK ###
_build_netatalk() {
local VERSION="3.1.8"
local FOLDER="netatalk-${VERSION}"
local FILE="${FOLDER}.tar.bz2"
local URL="http://sourceforge.net/projects/netatalk/files/netatalk/${VERSION}/${FILE}"

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-force-user.patch" "target/${FOLDER}/"
cp -vf "src/${FOLDER}-increase-flush-interval.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 -i "${FOLDER}-force-user.patch"
patch -p1 -i "${FOLDER}-increase-flush-interval.patch"
# See: http://sourceforge.net/p/netatalk/bugs/574/
sed -i '64i#define O_IGNORE 0' "include/atalk/acl.h"
autoreconf -i
./configure --host="${HOST}" --prefix="" \
  --localstatedir="/mnt/DroboFS/System" \
  --with-uams-path="/lib/netatalk" \
  --enable-shared --disable-static \
  --with-shadow --without-pam \
  --with-cnid-cdb-backend --with-cnid-default-backend=dbd \
  --with-libgcrypt-dir="${DEPS}" --with-bdb="${DEPS}" \
  --with-ssl-dir="${DEPS}" \
  LIBS="-ldl"
make
make install DESTDIR="${DEST}"
"${STRIP}" -s -R .comment -R .note -R .note.ABI-tag \
  "${DEST}/sbin/"* \
  "${DEST}/bin/"* \
  "${DEST}/lib/"*.so \
  "${DEST}/lib/netatalk/"*.so || true
popd
}

_build_rootfs() {
# bin/attr
# bin/getfattr
# bin/hmac256
# bin/setfattr
# lib/libatalk.so
# lib/libatalk.so.17
# lib/libatalk.so.17.0.0
# lib/netatalk/uams_dhx2_passwd.so
# lib/netatalk/uams_dhx_passwd.so
# lib/netatalk/uams_guest.so
# lib/netatalk/uams_passwd.so
# lib/netatalk/uams_randnum.so
# sbin/afpd
# sbin/cnid_dbd
# sbin/cnid_metad
# sbin/netatalk
  return 0
}

_build() {
  _build_zlib
  _build_openssl
  _build_bdb
  _build_libgpg_error
  _build_libgcrypt
  _build_libattr
  _build_netatalk
  _package
}
