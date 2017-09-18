export CPPFLAGS=-I/opt/cross/arm-linux-gnueabi/include/openssl
export LDFLAGS=-L/opt/cross/arm-linux-gnueabi/lib
export LIBS="-lssl -lcrypto"

./configure --with-ssl --with-zlib --host=arm-linux-gnueabi --prefix=/opt/cross/arm-linux-gnueabi

