#!/bin/bash


export LINUX_MAJOR_VERSION=v3.x
export LINUX_VERSION=3.19.8

export BINUTILS_VERSION=2.29.1
export GCC_VERSION=6.4.0
export GLIBC_VERSION=2.26

export LINUX_SRC=linux-$LINUX_VERSION
export BINUTILS_SRC=binutils-$BINUTILS_VERSION
export GCC_SRC=gcc-$GCC_VERSION
export GLIBC_SRC=glibc-$GLIBC_VERSION


export TARGET=arm-linux-gnueabihf
export PATH=$CROSS/bin:$PATH

export CROSS=/opt/${TARGET}_${LINUX_SRC}_${BINUTILS_SRC}_${GCC_SRC}_${GLIBC_SRC}

sudo mkdir -pv $CROSS
sudo chown $USER:$USER $CROSS


# Download source if not exist.
if [ ! -f ${BINUTILS_SRC}.tar.xz ]; then
    wget https://ftp.gnu.org/gnu/binutils/${BINUTILS_SRC}.tar.xz
fi

if [ ! -f ${GCC_SRC}.tar.xz ]; then
    wget https://ftp.gnu.org/gnu/gcc/$GCC_SRC/${GCC_SRC}.tar.xz
fi

if [ ! -f ${GLIBC_SRC}.tar.xz ]; then
    wget https://ftp.gnu.org/gnu/glibc/${GLIBC_SRC}.tar.xz
fi

if [ ! -f ${LINUX_SRC}.tar.xz ]; then
    wget https://www.kernel.org/pub/linux/kernel/$LINUX_MAJOR_VERSION/${LINUX_SRC}.tar.xz
fi


# Extract all the source packages.
for f in *.tar*; do
    echo "tar -xf $f"
    tar -xvf $f
done


# 1. Binutils
mkdir -pv binutils-build
cd binutils-build
../$BINUTILS_SRC/configure --prefix=$CROSS --target=$TARGET --disable-multilib --disable-nls
make -j8
make install
cd ..


# 2. Linux Kernel Headers
cd $LINUX_SRC
make ARCH=arm INSTALL_HDR_PATH=$CROSS/$TARGET headers_install
cd ..


# 3. C/C++ Compilers
cd $GCC_SRC
contrib/download_prerequisites
cd ..

mkdir -p gcc-build
cd gcc-build
../$GCC_SRC/configure --prefix=$CROSS --target=$TARGET --enable-languages=c,c++ --disable-multilib --disable-nls
make -j8 all-gcc
make install-gcc
cd ..


# 4. Standard C Library Headers and Startup Files
mkdir -p glibc-build
cd glibc-build
../$GLIBC_SRC/configure \
    --prefix=$CROSS/$TARGET \
    --build=$MACHTYPE \
    --host=$TARGET \
    --target=$TARGET \
    --with-headers=$CROSS/$TARGET/include \
    --disable-multilib \
    libc_cv_forced_unwind=yes \
    libc_cv_c_cleanup=yes
make install-bootstrap-headers=yes install-headers
make -j4 csu/subdir_lib
install csu/crt1.o csu/crti.o csu/crtn.o $CROSS/$TARGET/lib
touch $CROSS/$TARGET/include/gnu/stubs.h
$CROSS/bin/${TARGET}-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $CROSS/$TARGET/lib/libc.so
cd ..

# 5. Compiler Support Library
cd gcc-build
make -j8 all-target-libgcc
make install-target-libgcc
cd ..

# 6. Standard C Library
cd glibc-build
make -j8
make install
cd ..

# 7. Standard C++ Library
cd gcc-build
make -j8
make install
cd ..
