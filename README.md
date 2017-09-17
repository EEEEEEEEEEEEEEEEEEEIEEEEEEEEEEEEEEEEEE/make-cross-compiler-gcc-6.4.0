# make-cross-compiler-gcc-6.4.0
交叉编译器6.4.0

```bash
#!/bin/bash


# Extract all the source packages.
for f in *.tar*; do
    tar -xf $f
done


# Create symbolic links from the GCC directory to some of the other directories.
cd gcc-6.4.0
ln -s ../mpfr-3.1.6 mpfr
ln -s ../gmp-6.1.2 gmp
ln -s ../mpc-1.0.3 mpc
ln -s ../isl-0.18 isl
ln -s ../cloog-0.18.4 cloog
cd ..

export PATH=/opt/cross/bin:$PATH


# 1. Binutils
mkdir binutils-build
cd binutils-build
../binutils-2.29/configure --prefix=/opt/cross --target=arm-linux-gnueabi --disable-multilib 
make -j8
make install
cd ..

# 2. Linux Kernel Headers
cd linux-3.10.33
make ARCH=arm INSTALL_HDR_PATH=/opt/cross/arm-linux-gnueabi headers_install
cd ..

# 3. C/C++ Compilers
mkdir -p gcc-build
cd gcc-build
../gcc-6.4.0/configure --prefix=/opt/cross --target=arm-linux-gnueabi --enable-languages=c,c++ --disable-multilib
make -j8 all-gcc
make install-gcc
cd ..

# 4. Standard C Library Headers and Startup Files
mkdir -p glibc-build
cd glibc-build
../glibc-2.26/configure --prefix=/opt/cross/arm-linux-gnueabi --build=$MACHTYPE --host=arm-linux-gnueabi --target=arm-linux-gnueabi --with-headers=/opt/cross/arm-linux-gnueabi/include --disable-multilib libc_cv_forced_unwind=yes
make install-bootstrap-headers=yes install-headers
make -j4 csu/subdir_lib
install csu/crt1.o csu/crti.o csu/crtn.o /opt/cross/arm-linux-gnueabi/lib
touch /opt/cross/arm-linux-gnueabi/include/gnu/stubs.h
arm-linux-gnueabi-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o /opt/cross/arm-linux-gnueabi/lib/libc.so
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
```
