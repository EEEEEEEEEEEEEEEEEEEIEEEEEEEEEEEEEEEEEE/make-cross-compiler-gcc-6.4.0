export CPPFLAGS=-I/opt/arm/arm-linux-gnueabihf/include
export LDFLAGS=-L/opt/arm/arm-linux-gnueabihf/lib
export LIBS="-lssl -lcrypto"

./configure --enable-static --disable-shared LDFLAGS="-static" --with-ssl --with-zlib --host=arm-linux-gnueabihf --prefix=/opt/arm/arm-linux-gnueabihf
