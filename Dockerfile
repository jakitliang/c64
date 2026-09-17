FROM debian:bookworm-slim AS toolchain

ARG VERSION=1.0.0
ARG PREFIX=/c64
ARG GCC_PREFIX=$PREFIX/mingw64
ARG VIM_PREFIX=$PREFIX/opt/vim
ARG BINUTILS_VERSION=2.41
ARG BUSYBOX_VERSION=FRP-5857-g3681e397f
ARG CCACHE_VERSION=4.13.1
ARG CMAKE_VERSION=3.27.9
ARG CTAGS_VERSION=6.2.1
ARG EXPAT_VERSION=2.6.2
ARG GCC_FALLBACK_VERSION=13.5.0
ARG GCC_FALLBACK_SHA256=b70c44c68f75f0cf5f5ecf55a5339fce3b78ae21c6e81a2491514270e9ed5fe4
ARG GDB_VERSION=13.1
ARG GMP_VERSION=6.3.0
ARG LIBICONV_VERSION=1.17
ARG MAKE_VERSION=4.4.1
ARG MINGW_VERSION=11.0.1
ARG MPC_VERSION=1.3.1
ARG MPFR_VERSION=4.2.1
ARG NASM_VERSION=2.15.05
ARG NINJA_VERSION=1.12.1
ARG PDCURSES_VERSION=3.9
ARG CPPCHECK_VERSION=2.10
ARG VIM_VERSION=9.0
ARG XXHASH_VERSION=0.8.3
ARG ZSTD_VERSION=1.5.7

RUN apt-get update && apt-get install --yes --no-install-recommends \
       build-essential bzip2 cmake curl file flex libgmp-dev libmpc-dev libmpfr-dev m4 ninja-build python3 unzip zip

# Download, verify, and unpack only the compiler bootstrap inputs. Optional
# tools download immediately before their build, preserving this expensive cache.

RUN curl --insecure --location --remote-name-all --remote-header-name \
        https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.xz \
        https://ftp.gnu.org/gnu/gmp/gmp-$GMP_VERSION.tar.xz \
        https://ftp.gnu.org/gnu/mpc/mpc-$MPC_VERSION.tar.gz \
        https://ftp.gnu.org/gnu/mpfr/mpfr-$MPFR_VERSION.tar.xz \
        https://downloads.sourceforge.net/project/mingw-w64/mingw-w64/mingw-w64-release/mingw-w64-v$MINGW_VERSION.tar.bz2
# A vendored gcc-*tar.xz archive takes precedence when present. Copy the
# directory rather than a named archive so a clean vendor directory still
# permits the c64-maintained fallback.
COPY vendor/ /vendor/
COPY src/SHA256SUMS.core $PREFIX/src/
RUN sha256sum -c $PREFIX/src/SHA256SUMS.core \
 && tar xJf binutils-$BINUTILS_VERSION.tar.xz \
 && set -- /vendor/gcc-*tar.xz \
 && if test -f "$1"; then \
              test "$#" = 1; \
              echo "Using vendored GCC archive: $1"; \
              mkdir gcc; \
              tar xJf "$1" -C gcc --strip-components=1; \
       else \
              echo "Vendored GCC archive not found; downloading GCC $GCC_FALLBACK_VERSION"; \
              curl --insecure --location --output gcc-$GCC_FALLBACK_VERSION.tar.gz \
                     https://github.com/jakitliang/gcc/archive/refs/tags/$GCC_FALLBACK_VERSION.tar.gz; \
              printf '%s  %s\n' "$GCC_FALLBACK_SHA256" "gcc-$GCC_FALLBACK_VERSION.tar.gz" | sha256sum -c; \
              mkdir gcc; \
              tar xzf gcc-$GCC_FALLBACK_VERSION.tar.gz -C gcc --strip-components=1; \
       fi \
 && tar xJf gmp-$GMP_VERSION.tar.xz \
 && tar xzf mpc-$MPC_VERSION.tar.gz \
 && tar xJf mpfr-$MPFR_VERSION.tar.xz \
 && tar xjf mingw-w64-v$MINGW_VERSION.tar.bz2
COPY src/libmemory.c src/libchkstk.S src/alias.c \
     $PREFIX/src/

ARG ARCH=x86_64-w64-mingw32

# Build cross-compiler

WORKDIR /binutils-$BINUTILS_VERSION
RUN sed -ri 's/(static bool insert_timestamp = )/\1!/' ld/emultempl/pe*.em
WORKDIR /x-binutils
RUN /binutils-$BINUTILS_VERSION/configure \
        --prefix=/bootstrap \
        --with-sysroot=/bootstrap/$ARCH \
        --target=$ARCH \
        --disable-nls \
        --with-static-standard-libraries \
        --disable-multilib \
 && make MAKEINFO=true -j$(nproc) \
 && make MAKEINFO=true install

# Fixes i686 Windows XP regression
# https://sourceforge.net/p/mingw-w64/bugs/821/
RUN sed -i /OpenThreadToken/d /mingw-w64-v$MINGW_VERSION/mingw-w64-crt/lib32/kernel32.def

WORKDIR /x-mingw-headers
RUN /mingw-w64-v$MINGW_VERSION/mingw-w64-headers/configure \
        --prefix=/bootstrap/$ARCH \
        --host=$ARCH \
        --with-default-msvcrt=msvcrt-os \
 && make -j$(nproc) \
 && make install

WORKDIR /bootstrap
RUN ln -s $ARCH mingw

WORKDIR /x-gcc
COPY src/gcc-*.patch $PREFIX/src/
RUN cat $PREFIX/src/gcc-*.patch | patch -d/gcc -p1 \
 && /gcc/configure \
        --prefix=/bootstrap \
        --with-sysroot=/bootstrap \
        --target=$ARCH \
        --enable-static \
        --disable-shared \
        --with-pic \
        --enable-languages=c,c++ \
        --enable-libgomp \
        --enable-threads=posix \
        --enable-version-specific-runtime-libs \
        --disable-dependency-tracking \
        --disable-nls \
        --disable-lto \
        --disable-multilib \
        CFLAGS_FOR_TARGET="-Os" \
        CXXFLAGS_FOR_TARGET="-Os" \
        LDFLAGS_FOR_TARGET="-s" \
        CFLAGS="-Os" \
        CXXFLAGS="-Os" \
        LDFLAGS="-s" \
 && make -j$(nproc) all-gcc \
 && make install-gcc

ENV PATH="/bootstrap/bin:${PATH}"

RUN mkdir -p $GCC_PREFIX/$ARCH/lib \
 && CC=$ARCH-gcc DESTDIR=$GCC_PREFIX/$ARCH/lib/ sh $PREFIX/src/libmemory.c \
 && ln $GCC_PREFIX/$ARCH/lib/libmemory.a /bootstrap/$ARCH/lib/ \
 && CC=$ARCH-gcc DESTDIR=$GCC_PREFIX/$ARCH/lib/ sh $PREFIX/src/libchkstk.S \
 && ln $GCC_PREFIX/$ARCH/lib/libchkstk.a /bootstrap/$ARCH/lib/

WORKDIR /x-mingw-crt
RUN /mingw-w64-v$MINGW_VERSION/mingw-w64-crt/configure \
        --prefix=/bootstrap/$ARCH \
        --with-sysroot=/bootstrap/$ARCH \
        --host=$ARCH \
        --with-default-msvcrt=msvcrt-os \
        --disable-dependency-tracking \
        --disable-lib32 \
        --enable-lib64 \
        CFLAGS="-Os" \
        LDFLAGS="-s" \
 && make -j$(nproc) \
 && make install

WORKDIR /x-winpthreads
RUN /mingw-w64-v$MINGW_VERSION/mingw-w64-libraries/winpthreads/configure \
        --prefix=/bootstrap/$ARCH \
        --with-sysroot=/bootstrap/$ARCH \
        --host=$ARCH \
        --enable-static \
        --disable-shared \
        CFLAGS="-Os" \
        LDFLAGS="-s" \
 && make -j$(nproc) \
 && make install

WORKDIR /x-gcc
RUN make -j$(nproc) \
 && make install

# Cross-compile GCC

WORKDIR /binutils
RUN /binutils-$BINUTILS_VERSION/configure \
       --prefix=$GCC_PREFIX \
       --with-sysroot=$GCC_PREFIX/$ARCH \
        --host=$ARCH \
        --target=$ARCH \
        --disable-nls \
        --with-static-standard-libraries \
        CFLAGS="-Os" \
        LDFLAGS="-s" \
 && make MAKEINFO=true -j$(nproc) \
 && make MAKEINFO=true install \
 && rm $GCC_PREFIX/bin/elfedit.exe $GCC_PREFIX/bin/readelf.exe

WORKDIR /gmp
RUN /gmp-$GMP_VERSION/configure \
        --prefix=/deps \
        --host=$ARCH \
        --disable-assembly \
        --enable-static \
        --disable-shared \
        CFLAGS="-Os" \
        CXXFLAGS="-Os" \
        LDFLAGS="-s" \
 && make -j$(nproc) \
 && make install

WORKDIR /mpfr
RUN /mpfr-$MPFR_VERSION/configure \
        --prefix=/deps \
        --host=$ARCH \
        --with-gmp-include=/deps/include \
        --with-gmp-lib=/deps/lib \
        --enable-static \
        --disable-shared \
        CFLAGS="-Os" \
        LDFLAGS="-s" \
 && make -j$(nproc) \
 && make install

WORKDIR /mpc
RUN /mpc-$MPC_VERSION/configure \
        --prefix=/deps \
        --host=$ARCH \
        --with-gmp-include=/deps/include \
        --with-gmp-lib=/deps/lib \
        --with-mpfr-include=/deps/include \
        --with-mpfr-lib=/deps/lib \
        --enable-static \
        --disable-shared \
        CFLAGS="-Os" \
        LDFLAGS="-s" \
 && make -j$(nproc) \
 && make install

WORKDIR /mingw-headers
RUN /mingw-w64-v$MINGW_VERSION/mingw-w64-headers/configure \
       --prefix=$GCC_PREFIX/$ARCH \
        --host=$ARCH \
        --with-default-msvcrt=msvcrt-os \
 && make -j$(nproc) \
 && make install

WORKDIR /mingw-crt
RUN /mingw-w64-v$MINGW_VERSION/mingw-w64-crt/configure \
       --prefix=$GCC_PREFIX/$ARCH \
       --with-sysroot=$GCC_PREFIX/$ARCH \
        --host=$ARCH \
        --with-default-msvcrt=msvcrt-os \
        --disable-dependency-tracking \
        --disable-lib32 \
        --enable-lib64 \
        CFLAGS="-Os" \
        LDFLAGS="-s" \
 && make -j$(nproc) \
 && make install

WORKDIR /winpthreads
RUN /mingw-w64-v$MINGW_VERSION/mingw-w64-libraries/winpthreads/configure \
       --prefix=$GCC_PREFIX/$ARCH \
       --with-sysroot=$GCC_PREFIX/$ARCH \
        --host=$ARCH \
        --enable-static \
        --disable-shared \
        CFLAGS="-Os" \
        LDFLAGS="-s" \
 && make -j$(nproc) \
 && make install

WORKDIR /gcc
RUN /gcc/configure \
       --prefix=$GCC_PREFIX \
       --with-sysroot=$GCC_PREFIX/$ARCH \
        --with-native-system-header-dir=/include \
        --target=$ARCH \
        --host=$ARCH \
        --enable-static \
        --disable-shared \
        --with-pic \
        --with-gmp-include=/deps/include \
        --with-gmp-lib=/deps/lib \
        --with-mpc-include=/deps/include \
        --with-mpc-lib=/deps/lib \
        --with-mpfr-include=/deps/include \
        --with-mpfr-lib=/deps/lib \
        --enable-languages=c,c++ \
        --enable-libgomp \
        --enable-threads=posix \
        --enable-version-specific-runtime-libs \
        --disable-dependency-tracking \
        --disable-lto \
        --disable-multilib \
        --disable-nls \
        --disable-win32-registry \
        --enable-mingw-wildcard \
        CFLAGS_FOR_TARGET="-Os" \
        CXXFLAGS_FOR_TARGET="-Os" \
        LDFLAGS_FOR_TARGET="-s" \
        CFLAGS="-Os" \
        CXXFLAGS="-Os" \
        LDFLAGS="-s" \
 && make -j$(nproc) \
 && make install \
 && rm -rf $GCC_PREFIX/$ARCH/bin/ $GCC_PREFIX/bin/$ARCH-* \
        $GCC_PREFIX/bin/ld.bfd.exe $GCC_PREFIX/bin/c++.exe \
 && $ARCH-gcc -DEXE=g++.exe -DCMD=c++ \
        -Os -fno-asynchronous-unwind-tables \
        -Wl,--gc-sections -s -nostdlib \
       -o $GCC_PREFIX/bin/c++.exe \
        $PREFIX/src/alias.c -lkernel32

# Create various tool aliases
RUN $ARCH-gcc -DEXE=gcc.exe -DCMD=cc \
        -Os -fno-asynchronous-unwind-tables -Wl,--gc-sections -s -nostdlib \
       -o $GCC_PREFIX/bin/cc.exe $PREFIX/src/alias.c -lkernel32 \
 && $ARCH-gcc -DEXE=gcc.exe -DCMD="cc -std=c99" \
        -Os -fno-asynchronous-unwind-tables -Wl,--gc-sections -s -nostdlib \
       -o $GCC_PREFIX/bin/c99.exe $PREFIX/src/alias.c -lkernel32 \
 && $ARCH-gcc -DEXE=gcc.exe -DCMD="cc -ansi" \
        -Os -fno-asynchronous-unwind-tables -Wl,--gc-sections -s -nostdlib \
       -o $GCC_PREFIX/bin/c89.exe $PREFIX/src/alias.c -lkernel32 \
 && printf '%s\n' addr2line ar as c++filt cpp dlltool dllwrap elfedit g++ \
      gcc gcc-ar gcc-nm gcc-ranlib gcov gcov-dump gcov-tool ld nm objcopy \
      objdump ranlib readelf size strings strip windmc windres \
    | xargs -I{} -P$(nproc) \
          $ARCH-gcc -DEXE={}.exe -DCMD=$ARCH-{} \
            -Os -fno-asynchronous-unwind-tables \
            -Wl,--gc-sections -s -nostdlib \
            -o $GCC_PREFIX/bin/$ARCH-{}.exe $PREFIX/src/alias.c -lkernel32

# Build Ctags independently from the common toolchain.
FROM toolchain AS build-ctags
COPY src/SHA256SUMS.ctags $PREFIX/src/
WORKDIR /
RUN curl --insecure --location --remote-name-all --remote-header-name \
       https://github.com/universal-ctags/ctags/archive/refs/tags/v$CTAGS_VERSION.tar.gz \
 && sha256sum -c $PREFIX/src/SHA256SUMS.ctags \
 && tar xzf ctags-$CTAGS_VERSION.tar.gz
WORKDIR /ctags-$CTAGS_VERSION
RUN sed -i /RT_MANIFEST/d win32/ctags.rc \
 && make -j$(nproc) -f mk_mingw.mak CC=gcc packcc.exe \
 && make -j$(nproc) -f mk_mingw.mak \
       CC=$ARCH-gcc WINDRES=$ARCH-windres \
       OPT= CFLAGS=-Os LDFLAGS=-s
RUN mkdir -p /artifacts/ctags$PREFIX/bin \
 && cp ctags.exe /artifacts/ctags$PREFIX/bin/

# Build gendef independently from the common toolchain.
FROM toolchain AS build-gendef

WORKDIR /mingw-tools/gendef
COPY src/gendef-silent.patch $PREFIX/src/
RUN patch -d/mingw-w64-v$MINGW_VERSION -p1 <$PREFIX/src/gendef-silent.patch \
 && /mingw-w64-v$MINGW_VERSION/mingw-w64-tools/gendef/configure \
        --host=$ARCH \
        CFLAGS="-Os" \
        LDFLAGS="-s" \
 && make -j$(nproc) \
 && mkdir -p /artifacts/gendef$GCC_PREFIX/bin \
 && cp gendef.exe /artifacts/gendef$GCC_PREFIX/bin/

# Build Ccache independently from the common toolchain.
FROM toolchain AS build-ccache
COPY src/SHA256SUMS.ccache $PREFIX/src/
WORKDIR /
RUN curl --insecure --location --remote-name-all --remote-header-name \
       https://github.com/ccache/ccache/releases/download/v$CCACHE_VERSION/ccache-$CCACHE_VERSION.tar.xz \
       https://github.com/Cyan4973/xxHash/archive/refs/tags/v$XXHASH_VERSION.tar.gz \
       https://github.com/facebook/zstd/releases/download/v$ZSTD_VERSION/zstd-$ZSTD_VERSION.tar.gz \
 && tr -d '\r' <$PREFIX/src/SHA256SUMS.ccache \
        | grep -E "  (ccache-$CCACHE_VERSION.tar.xz|xxHash-$XXHASH_VERSION.tar.gz|zstd-$ZSTD_VERSION.tar.gz)$" \
        | sha256sum -c \
 && tar xJf ccache-$CCACHE_VERSION.tar.xz \
 && tar xzf xxHash-$XXHASH_VERSION.tar.gz \
 && tar xzf zstd-$ZSTD_VERSION.tar.gz

WORKDIR /xxHash-$XXHASH_VERSION
RUN make -j$(nproc) CC=$ARCH-gcc AR=$ARCH-ar CFLAGS="-Os" libxxhash.a \
 && cp libxxhash.a /deps/lib/ \
 && cp xxhash.h /deps/include/

WORKDIR /zstd-$ZSTD_VERSION/lib
RUN make -j$(nproc) CC=$ARCH-gcc AR=$ARCH-ar CFLAGS="-Os" libzstd.a \
 && cp libzstd.a /deps/lib/ \
 && cp zstd.h zstd_errors.h zdict.h /deps/include/

WORKDIR /ccache
RUN cmake -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCMAKE_SYSTEM_NAME=Windows \
        -DCMAKE_C_COMPILER=$ARCH-gcc \
        -DCMAKE_CXX_COMPILER=$ARCH-g++ \
        -DCMAKE_RC_COMPILER=$ARCH-windres \
        -DCMAKE_FIND_ROOT_PATH=/deps \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_EXE_LINKER_FLAGS="-s" \
        -DDEPS=LOCAL \
        -DREDIS_STORAGE_BACKEND=OFF \
        -DHTTP_STORAGE_BACKEND=OFF \
        -DENABLE_TESTING=OFF \
        -DENABLE_DOCUMENTATION=OFF \
        /ccache-$CCACHE_VERSION \
 && make -j$(nproc) \
 && mkdir -p $GCC_PREFIX/bin $GCC_PREFIX/lib/ccache \
 && cp ccache.exe $GCC_PREFIX/bin/ \
 && $ARCH-gcc -DEXE=ccache.exe -DCMD=gcc \
        -Os -fno-asynchronous-unwind-tables -Wl,--gc-sections -s -nostdlib \
        -o $GCC_PREFIX/bin/ccache-gcc.exe $PREFIX/src/alias.c -lkernel32 \
 && $ARCH-gcc -DEXE=ccache.exe -DCMD=g++ \
        -Os -fno-asynchronous-unwind-tables -Wl,--gc-sections -s -nostdlib \
        -o $GCC_PREFIX/bin/ccache-g++.exe $PREFIX/src/alias.c -lkernel32 \
 && printf '%s\n' gcc cc c89 c99 $ARCH-gcc \
    | xargs -I{} -P$(nproc) \
        $ARCH-gcc -DEXE=../bin/ccache.exe -DCMD=gcc \
          -Os -fno-asynchronous-unwind-tables \
          -Wl,--gc-sections -s -nostdlib \
          -o $GCC_PREFIX/lib/ccache/{}.com $PREFIX/src/alias.c -lkernel32 \
 && printf '%s\n' g++ c++ $ARCH-g++ \
    | xargs -I{} -P$(nproc) \
              $ARCH-gcc -DEXE=../bin/ccache.exe -DCMD=g++ \
          -Os -fno-asynchronous-unwind-tables \
          -Wl,--gc-sections -s -nostdlib \
          -o $GCC_PREFIX/lib/ccache/{}.com $PREFIX/src/alias.c -lkernel32
RUN mkdir -p /artifacts/ccache$GCC_PREFIX \
 && cp -a $GCC_PREFIX/bin $GCC_PREFIX/lib /artifacts/ccache$GCC_PREFIX/

# Build CMake and Ninja independently from the common toolchain.
FROM toolchain AS build-cmake
COPY src/SHA256SUMS.cmake $PREFIX/src/
WORKDIR /
RUN curl --insecure --location --remote-name-all --remote-header-name \
       https://downloads.sourceforge.net/project/pdcurses/pdcurses/$PDCURSES_VERSION/PDCurses-$PDCURSES_VERSION.tar.gz \
 && tr -d '\r' <$PREFIX/src/SHA256SUMS.cmake | grep "  PDCurses-$PDCURSES_VERSION.tar.gz$" | sha256sum -c \
 && tar xzf PDCurses-$PDCURSES_VERSION.tar.gz
WORKDIR /PDCurses-$PDCURSES_VERSION
RUN make -j$(nproc) -C wincon \
        CC=$ARCH-gcc AR=$ARCH-ar CFLAGS="-I.. -Os -DPDC_WIDE" pdcurses.a \
 && mkdir -p /deps/lib /deps/include \
 && cp wincon/pdcurses.a /deps/lib/libcurses.a \
 && cp curses.h /deps/include

WORKDIR /
RUN curl --insecure --location --remote-name-all --remote-header-name \
        https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION.tar.gz \
 && tr -d '\r' <$PREFIX/src/SHA256SUMS.cmake | grep "  cmake-$CMAKE_VERSION.tar.gz$" | sha256sum -c \
 && tar xzf cmake-$CMAKE_VERSION.tar.gz

WORKDIR /cmake
RUN cmake -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCMAKE_SYSTEM_NAME=Windows \
        -DCMAKE_C_COMPILER=$ARCH-gcc \
        -DCMAKE_CXX_COMPILER=$ARCH-g++ \
        -DCMAKE_RC_COMPILER=$ARCH-windres \
        -DCMAKE_EXE_LINKER_FLAGS="-s" \
       -DCMAKE_INSTALL_PREFIX=$GCC_PREFIX \
        -DBUILD_CursesDialog=ON \
        -DCURSES_LIBRARY=/deps/lib/libcurses.a \
        -DCURSES_INCLUDE_PATH=/deps/include \
        -DBUILD_QtDialog=OFF \
        -DBUILD_TESTING=OFF \
        -DCMAKE_USE_OPENSSL=OFF \
        /cmake-$CMAKE_VERSION \
 && make -j$(nproc) \
 && make install \
 && rm -rf $GCC_PREFIX/doc/ $GCC_PREFIX/man/

WORKDIR /
RUN curl --insecure --location --remote-name-all --remote-header-name \
        https://github.com/ninja-build/ninja/archive/refs/tags/v$NINJA_VERSION.tar.gz \
 && tr -d '\r' <$PREFIX/src/SHA256SUMS.cmake | grep "  ninja-$NINJA_VERSION.tar.gz$" | sha256sum -c \
 && tar xzf ninja-$NINJA_VERSION.tar.gz

WORKDIR /ninja
RUN sed -i 's/^if(platform_supports_ninja_browse)$/if(0)/' /ninja-$NINJA_VERSION/CMakeLists.txt \
 && cmake -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCMAKE_SYSTEM_NAME=Windows \
       -DCMAKE_C_COMPILER=$ARCH-gcc \
        -DCMAKE_CXX_COMPILER=$ARCH-g++ \
        -DCMAKE_EXE_LINKER_FLAGS="-s" \
        -DBUILD_TESTING=OFF \
        /ninja-$NINJA_VERSION \
 && make -j$(nproc) \
 && cp ninja.exe $GCC_PREFIX/bin/
RUN mkdir -p /artifacts/cmake$GCC_PREFIX \
 && cp -a $GCC_PREFIX/bin $GCC_PREFIX/share /artifacts/cmake$GCC_PREFIX/

# Build GDB independently from the common toolchain.
FROM toolchain AS build-gdb
COPY src/SHA256SUMS.gdb $PREFIX/src/
WORKDIR /
RUN curl --insecure --location --remote-name-all --remote-header-name \
       https://github.com/libexpat/libexpat/releases/download/R_$(echo $EXPAT_VERSION | tr . _)/expat-$EXPAT_VERSION.tar.xz \
       https://downloads.sourceforge.net/project/pdcurses/pdcurses/$PDCURSES_VERSION/PDCurses-$PDCURSES_VERSION.tar.gz \
 && tr -d '\r' <$PREFIX/src/SHA256SUMS.gdb \
        | grep -E "  (expat-$EXPAT_VERSION.tar.xz|PDCurses-$PDCURSES_VERSION.tar.gz)$" \
        | sha256sum -c \
 && tar xJf expat-$EXPAT_VERSION.tar.xz \
 && tar xzf PDCurses-$PDCURSES_VERSION.tar.gz
WORKDIR /expat
RUN /expat-$EXPAT_VERSION/configure --prefix=/deps --host=$ARCH --disable-shared \
        --without-docbook --without-examples --without-tests CFLAGS="-Os" LDFLAGS="-s" \
 && make -j$(nproc) && make install
WORKDIR /PDCurses-$PDCURSES_VERSION
RUN make -j$(nproc) -C wincon \
        CC=$ARCH-gcc AR=$ARCH-ar CFLAGS="-I.. -Os -DPDC_WIDE" pdcurses.a \
 && cp wincon/pdcurses.a /deps/lib/libcurses.a \
 && cp curses.h /deps/include

WORKDIR /
RUN curl --insecure --location --remote-name-all --remote-header-name \
        https://ftp.gnu.org/gnu/libiconv/libiconv-$LIBICONV_VERSION.tar.gz \
 && tr -d '\r' <$PREFIX/src/SHA256SUMS.gdb | grep "  libiconv-$LIBICONV_VERSION.tar.gz$" | sha256sum -c \
 && tar xzf libiconv-$LIBICONV_VERSION.tar.gz

WORKDIR /libiconv
RUN /libiconv-$LIBICONV_VERSION/configure \
        --prefix=/deps \
        --host=$ARCH \
        --disable-nls \
        --disable-shared \
        CFLAGS="-Os" \
        LDFLAGS="-s" \
 && make -j$(nproc) \
 && make install

WORKDIR /
RUN curl --insecure --location --remote-name-all --remote-header-name \
        https://ftp.gnu.org/gnu/gdb/gdb-$GDB_VERSION.tar.xz \
 && tr -d '\r' <$PREFIX/src/SHA256SUMS.gdb | grep "  gdb-$GDB_VERSION.tar.xz$" | sha256sum -c \
 && tar xJf gdb-$GDB_VERSION.tar.xz

WORKDIR /gdb
COPY src/gdb-*.patch $PREFIX/src/
RUN cat $PREFIX/src/gdb-*.patch | patch -d/gdb-$GDB_VERSION -p1 \
 && sed -i 's/quiet = 0/quiet = 1/' /gdb-$GDB_VERSION/gdb/main.c \
 && /gdb-$GDB_VERSION/configure \
        --host=$ARCH \
        --enable-tui \
        CFLAGS="-Os -DPDC_WIDE -I/deps/include" \
        CXXFLAGS="-Os -DPDC_WIDE -I/deps/include" \
        LDFLAGS="-s -L/deps/lib" \
 && make MAKEINFO=true -j$(nproc) \
 && cp gdb/.libs/gdb.exe gdbserver/gdbserver.exe $GCC_PREFIX/bin/
RUN mkdir -p /artifacts/gdb$GCC_PREFIX \
 && cp -a $GCC_PREFIX/bin /artifacts/gdb$GCC_PREFIX/

# Build Make independently from the common toolchain.
FROM toolchain AS build-extras
COPY src/SHA256SUMS.make $PREFIX/src/
WORKDIR /
RUN curl --insecure --location --remote-name-all --remote-header-name \
        https://ftp.gnu.org/gnu/make/make-$MAKE_VERSION.tar.gz \
 && sha256sum -c $PREFIX/src/SHA256SUMS.make \
 && tar xzf make-$MAKE_VERSION.tar.gz

WORKDIR /make
RUN /make-$MAKE_VERSION/configure \
        --host=$ARCH \
        --disable-nls \
        CFLAGS="-Os" \
        LDFLAGS="-s" \
 && make -j$(nproc) \
 && mkdir -p $PREFIX/bin \
 && cp make.exe $PREFIX/bin/ \
 && $ARCH-gcc -DEXE=make.exe -DCMD=make \
        -Os -fno-asynchronous-unwind-tables \
        -Wl,--gc-sections -s -nostdlib \
        -o $GCC_PREFIX/bin/mingw32-make.exe $PREFIX/src/alias.c -lkernel32
RUN mkdir -p /artifacts/extras$PREFIX /artifacts/extras$GCC_PREFIX \
 && cp -a $PREFIX/bin /artifacts/extras$PREFIX/ \
 && cp -a $GCC_PREFIX/bin /artifacts/extras$GCC_PREFIX/

# Build BusyBox independently from the common toolchain.
FROM toolchain AS build-busybox
COPY src/SHA256SUMS.busybox $PREFIX/src/
WORKDIR /
RUN curl --insecure --location --remote-name-all --remote-header-name \
       https://frippery.org/files/busybox/busybox-w32-$BUSYBOX_VERSION.tgz \
 && sha256sum -c $PREFIX/src/SHA256SUMS.busybox \
 && tar xzf busybox-w32-$BUSYBOX_VERSION.tgz

WORKDIR /busybox-w32
COPY src/busybox-* $PREFIX/src/
RUN cat $PREFIX/src/busybox-*.patch | patch -p1 \
 && make mingw64_defconfig \
 && sed -ri 's/^(CONFIG_AR)=y/\1=n/' .config \
 && sed -ri 's/^(CONFIG_ASCII)=y/\1=n/' .config \
 && sed -ri 's/^(CONFIG_DPKG\w*)=y/\1=n/' .config \
 && sed -ri 's/^(CONFIG_FTP\w*)=y/\1=n/' .config \
 && sed -ri 's/^(CONFIG_LINK)=y/\1=n/' .config \
 && sed -ri 's/^(CONFIG_MAN)=y/\1=n/' .config \
 && sed -ri 's/^(CONFIG_MAKE)=y/\1=n/' .config \
 && sed -ri 's/^(CONFIG_PDPMAKE)=y/\1=n/' .config \
 && sed -ri 's/^(CONFIG_RPM\w*)=y/\1=n/' .config \
 && sed -ri 's/^(CONFIG_STRINGS)=y/\1=n/' .config \
 && sed -ri 's/^(CONFIG_TEST2)=y/\1=n/' .config \
 && sed -ri 's/^(CONFIG_TSORT)=y/\1=n/' .config \
 && sed -ri 's/^(CONFIG_UNLINK)=y/\1=n/' .config \
 && sed -ri 's/^(CONFIG_VI)=y/\1=n/' .config \
 && sed -ri 's/^(CONFIG_XXD)=y/\1=n/' .config \
 && make -j$(nproc) CROSS_COMPILE=$ARCH- \
    CONFIG_EXTRA_CFLAGS="-D_WIN32_WINNT=0x502" \
 && mkdir -p $PREFIX/bin \
 && cp busybox.exe $PREFIX/bin/

# Create BusyBox command aliases (like "busybox --install")
RUN $ARCH-gcc -Os -fno-asynchronous-unwind-tables -Wl,--gc-sections -s \
      -nostdlib -o alias.exe $PREFIX/src/busybox-alias.c -lkernel32 \
 && printf '%s\n' arch ash awk base32 base64 basename bash bc bunzip2 bzcat \
      bzip2 cal cat chattr chmod cksum clear cmp comm cp cpio crc32 cut date \
      dc dd df diff dirname dos2unix du echo ed egrep env expand expr factor \
      false fgrep find fold free fsync getopt grep groups gunzip gzip hd \
      head hexdump httpd iconv id inotifyd install ipcalc jn kill killall \
      lash less ln logname ls lsattr lzcat lzma lzop lzopcat md5sum mkdir \
      mktemp mv nc nl nproc od paste patch pgrep pidof pipe_progress pkill \
      printenv printf ps pwd readlink realpath reset rev rm rmdir sed seq sh \
      sha1sum sha256sum sha3sum sha512sum shred shuf sleep sort split \
      ssl_client stat su sum sync tac tail tar tee test time timeout touch \
      tr true truncate ts ttysize uname uncompress unexpand uniq unix2dos \
      unlzma unlzop unxz unzip uptime usleep uudecode uuencode watch \
      wc wget which whoami whois xargs xz xzcat yes zcat \
    | xargs -I{} cp alias.exe $PREFIX/bin/{}.exe
RUN mkdir -p /artifacts/busybox$PREFIX \
 && cp -a $PREFIX/bin /artifacts/busybox$PREFIX/

# Build Vim independently from the common toolchain.
FROM toolchain AS build-vim
COPY src/SHA256SUMS.vim $PREFIX/src/
WORKDIR /
RUN curl --insecure --location --remote-name-all --remote-header-name \
          https://mirror.math.princeton.edu/pub/vim/unix/vim-$VIM_VERSION.tar.bz2 \
 && sha256sum -c $PREFIX/src/SHA256SUMS.vim \
 && tar xjf vim-$VIM_VERSION.tar.bz2

# TODO: Either somehow use $VIM_VERSION or normalize the workdir
WORKDIR /vim90/src
RUN ARCH= make -j$(nproc) -f Make_ming.mak \
        OPTIMIZE=SIZE STATIC_STDCPLUS=yes HAS_GCC_EH=no \
        UNDER_CYGWIN=yes CROSS=yes CROSS_COMPILE=$ARCH- \
        FEATURES=HUGE VIMDLL=yes NETBEANS=no WINVER=0x0501 \
 && $ARCH-strip vimrun.exe \
 && rm -rf ../runtime/tutor/tutor.* \
 && mkdir -p $PREFIX/bin $VIM_PREFIX \
 && cp -r ../runtime $VIM_PREFIX/ \
 && cp vimrun.exe gvim.exe vim.exe *.dll $VIM_PREFIX/ \
 && cp xxd/xxd.exe $PREFIX/bin \
 && printf '@set SHELL=\r\n@start "" "%%~dp0/../opt/vim/gvim.exe" %%*\r\n' \
        >$PREFIX/bin/gvim.bat \
 && printf '@set SHELL=\r\n@"%%~dp0/../opt/vim/vim.exe" %%*\r\n' \
        >$PREFIX/bin/vim.bat \
 && printf '@set SHELL=\r\n@"%%~dp0/../opt/vim/vim.exe" %%*\r\n' \
        >$PREFIX/bin/vi.bat \
 && printf '@vim -N -u NONE "+read %s" "+write" "%s"\r\n' \
        '$VIMRUNTIME/tutor/tutor' '%TMP%/tutor%RANDOM%' \
        >$PREFIX/bin/vimtutor.bat
RUN mkdir -p /artifacts/vim$PREFIX/opt \
 && cp -a $PREFIX/bin /artifacts/vim$PREFIX/ \
 && cp -a $VIM_PREFIX /artifacts/vim$PREFIX/opt/

# Build NASM and Cppcheck independently from the common toolchain.
FROM toolchain AS build-tools
COPY src/SHA256SUMS.tools $PREFIX/src/
WORKDIR /
RUN curl --insecure --location --remote-name-all --remote-header-name \
       https://www.nasm.us/pub/nasm/releasebuilds/$NASM_VERSION/nasm-$NASM_VERSION.tar.xz \
 && tr -d '\r' <$PREFIX/src/SHA256SUMS.tools | grep "  nasm-$NASM_VERSION.tar.xz$" | sha256sum -c \
 && tar xJf nasm-$NASM_VERSION.tar.xz

# NOTE: nasm's configure script is broken, so no out-of-source build
WORKDIR /nasm-$NASM_VERSION
RUN ./configure \
        --host=$ARCH \
        CFLAGS="-Os" \
        LDFLAGS="-s" \
 && make -j$(nproc) \
 && mkdir -p $PREFIX/bin \
 && cp nasm.exe ndisasm.exe $PREFIX/bin

WORKDIR /
RUN curl --insecure --location --remote-name-all --remote-header-name \
       https://github.com/danmar/cppcheck/archive/$CPPCHECK_VERSION.tar.gz \
 && tr -d '\r' <$PREFIX/src/SHA256SUMS.tools | grep "  cppcheck-$CPPCHECK_VERSION.tar.gz$" | sha256sum -c \
 && tar xzf cppcheck-$CPPCHECK_VERSION.tar.gz

WORKDIR /cppcheck-$CPPCHECK_VERSION
COPY src/cppcheck.mak src/cppcheck-*.patch $PREFIX/src/
RUN cat $PREFIX/src/cppcheck-*.patch | patch -p1 \
 && make -f $PREFIX/src/cppcheck.mak -j$(nproc) CXX=$ARCH-g++ \
 && mkdir -p $GCC_PREFIX/share/cppcheck/ \
 && cp -r cppcheck.exe cfg/ $GCC_PREFIX/share/cppcheck \
 && $ARCH-gcc -DEXE=../share/cppcheck/cppcheck.exe -DCMD=cppcheck \
        -Os -fno-asynchronous-unwind-tables -Wl,--gc-sections -s -nostdlib \
        -o $GCC_PREFIX/bin/cppcheck.exe \
        $PREFIX/src/alias.c -lkernel32
RUN mkdir -p /artifacts/extras$PREFIX /artifacts/extras$GCC_PREFIX \
 && cp -a $PREFIX/bin /artifacts/extras$PREFIX/ \
 && cp -a $GCC_PREFIX/bin $GCC_PREFIX/share /artifacts/extras$GCC_PREFIX/

# Pack up a release

FROM toolchain AS package
COPY --from=build-gendef /artifacts/gendef/ /
COPY --from=build-ctags /artifacts/ctags/ /
COPY --from=build-ccache /artifacts/ccache/ /
COPY --from=build-cmake /artifacts/cmake/ /
COPY --from=build-gdb /artifacts/gdb/ /
COPY --from=build-extras /artifacts/extras/ /
COPY --from=build-busybox /artifacts/busybox/ /
COPY --from=build-vim /artifacts/vim/ /
COPY --from=build-tools /artifacts/extras/ /
COPY vendor/clink.zip vendor/clink-completions.zip /vendor/
COPY src/SHA256SUMS.base $PREFIX/src/
RUN cd /vendor \
 && sha256sum -c $PREFIX/src/SHA256SUMS.base \
 && mkdir -p $PREFIX/etc/default $PREFIX/etc/profile.d $PREFIX/lib/clink $PREFIX/opt \
 && unzip -q /vendor/clink.zip -d $PREFIX/opt/ \
 && unzip -q /vendor/clink-completions.zip -d $PREFIX/opt/

WORKDIR /
RUN rm -rf $PREFIX/share/man/ $PREFIX/share/info/ $PREFIX/share/gcc-* \
        $GCC_PREFIX/share/gcc-* \
 && rm -rf $PREFIX/lib/*.a $PREFIX/lib/*.la $PREFIX/include/*.h \
        $GCC_PREFIX/lib/*.a $GCC_PREFIX/lib/*.la $GCC_PREFIX/include/*.h
COPY src/c64.c src/c64.ico src/debugbreak.c src/pkg-config.c \
       src/vc++filt.c src/peports.c src/profile \
     $PREFIX/src/
COPY src/profile $PREFIX/etc/profile
COPY src/profile.cmd $PREFIX/etc/profile.cmd
COPY src/profile $PREFIX/etc/default/profile.default
COPY src/profile.cmd $PREFIX/etc/default/profile.cmd.default
COPY src/default/ $PREFIX/etc/default/
COPY src/use.d/ $PREFIX/etc/use.d/
COPY src/c64-shell.cmd $PREFIX/c64_shell.cmd
COPY src/init.cmd $PREFIX/lib/c64/init.cmd
COPY src/c64-clink.lua $PREFIX/lib/clink/clink.lua
COPY src/c64-prompt.lua $PREFIX/lib/clink/c64-prompt.lua
COPY README.md LICENSE src/c64.ini $PREFIX/
RUN sed -i 's/\r$//' $PREFIX/etc/profile $PREFIX/etc/default/profile.default \
       $PREFIX/etc/use.d/*.sh
RUN printf "id ICON \"$PREFIX/src/c64.ico\"" >c64.rc \
 && $ARCH-windres -o c64.o c64.rc \
 && $ARCH-gcc -DVERSION=$VERSION -nostdlib -fno-asynchronous-unwind-tables \
        -fno-builtin -Wl,--gc-sections -s -o $PREFIX/c64.exe \
       $PREFIX/src/c64.c c64.o -lkernel32 -luser32 \
 && $ARCH-gcc \
        -Os -fno-asynchronous-unwind-tables \
        -Wl,--gc-sections -s -nostdlib \
        -o $PREFIX/bin/debugbreak.exe $PREFIX/src/debugbreak.c \
        -lkernel32 \
 && $ARCH-gcc \
        -Os -fno-asynchronous-unwind-tables -fno-builtin -Wl,--gc-sections \
        -s -nostdlib -DPKG_CONFIG_PREFIX="\"/$ARCH\"" \
        -o $GCC_PREFIX/bin/pkg-config.exe $PREFIX/src/pkg-config.c \
        -lkernel32 \
 && $ARCH-gcc \
        -Os -fno-asynchronous-unwind-tables -fno-builtin -Wl,--gc-sections \
        -s -nostdlib -o $PREFIX/bin/vc++filt.exe $PREFIX/src/vc++filt.c \
        -lkernel32 -lshell32 -ldbghelp \
 && $ARCH-gcc \
        -Os -fno-asynchronous-unwind-tables -fno-builtin -Wl,--gc-sections \
        -s -nostdlib -o $PREFIX/bin/peports.exe $PREFIX/src/peports.c \
        -lkernel32 -lshell32 \
 && $ARCH-gcc -DEXE=pkg-config.exe -DCMD=pkg-config \
        -Os -fno-asynchronous-unwind-tables -Wl,--gc-sections -s -nostdlib \
        -o $GCC_PREFIX/bin/$ARCH-pkg-config.exe $PREFIX/src/alias.c -lkernel32 \
 && mkdir -p $GCC_PREFIX/$ARCH/lib/pkgconfig \
 && cp /mingw-w64-v$MINGW_VERSION/COPYING.MinGW-w64-runtime/COPYING.MinGW-w64-runtime.txt \
        $PREFIX/ \
 && printf "\n===========\nwinpthreads\n===========\n\n" \
        >>$PREFIX/COPYING.MinGW-w64-runtime.txt . \
 && cat /mingw-w64-v$MINGW_VERSION/mingw-w64-libraries/winpthreads/COPYING \
        >>$PREFIX/COPYING.MinGW-w64-runtime.txt \
 && echo $VERSION >$PREFIX/VERSION.txt \
 && rm -rf $PREFIX/src
ENV PREFIX=${PREFIX}
CMD ["sh", "-c", "exec zip -q9Xr - \"$PREFIX\""]
