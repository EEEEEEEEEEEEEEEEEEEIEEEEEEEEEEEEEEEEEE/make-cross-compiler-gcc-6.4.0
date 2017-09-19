#!/bin/bash

export BINUTILS_VERSION=2.29
export GCC_VERSION=6.4.0
export GLIBC_VERSION=2.26

export LINUX_MAJOR_VERSION=v3.x
export LINUX_VERSION=3.10.33

export CROSS=/opt/toolchain-arm
export TARGET=arm-linux-gnueabihf
export PATH=$CROSS/bin:$PATH


if [ ! -f binutils-$BINUTILS_VERSION.tar.xz ]; then
    wget https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.xz
fi

if [ ! -f gcc-$GCC_VERSION.tar.xz ]; then
    wget https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz
fi

if [ ! -f glibc-$GLIBC_VERSION.tar.xz ]; then
    wget https://ftp.gnu.org/gnu/glibc/glibc-$GLIBC_VERSION.tar.xz
fi

if [ ! -f linux-$LINUX_VERSION.tar.xz ]; then
    wget https://www.kernel.org/pub/linux/kernel/$LINUX_MAJOR_VERSION/linux-$LINUX_VERSION.tar.xz
fi


# Extract all the source packages.
for f in *.tar*; do
    tar -xf $f
done


# 1. Binutils
mkdir -pv binutils-build
cd binutils-build
../binutils-$BINUTILS_VERSION/configure --prefix=$CROSS --target=$TARGET --disable-multilib
make -j8
make install
cd ..


# 2. Linux Kernel Headers
cd linux-$LINUX_VERSION
make ARCH=arm INSTALL_HDR_PATH=$CROSS/$TARGET headers_install
cd ..


# 3. C/C++ Compilers
cd gcc-$GCC_VERSION
contrib/download_prerequisites
cd ..
# Build and install gcc
mkdir -p gcc-build
cd gcc-build
../gcc-$GCC_VERSION/configure --prefix=$CROSS --target=$TARGET --enable-languages=c,c++ --disable-multilib
make -j8 all-gcc
make install-gcc
cd ..


# 4. Standard C Library Headers and Startup Files
mkdir -p glibc-build
cd glibc-build
../glibc-$GLIBC_VERSION/configure \
    --prefix=$CROSS/$TARGET \
    --build=$MACHTYPE \
    --host=$TARGET \
    --target=$TARGET \
    --with-headers=$CROSS/$TARGET/include \
    --disable-multilib libc_cv_forced_unwind=yes
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
