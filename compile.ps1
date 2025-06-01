$msys2Root = "C:\tools\msys64"

# Download MSYS2 if not present
if (-not (Test-Path $msys2Root)) {
    Write-Output "Installing MSYS2 via Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Output "Installing Chocolatey..."
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    choco install msys2 --yes
}

# Set up cross-compilation environment in MSYS2
Write-Output "Setting up cross-compilation environment..."

# Write the cross-compile script for MinGW64
$crossScript = @'
BINUTILS_VERSION="2.43"
GCC_VERSION="15.1.0"

pacman -Syu --noconfirm

pacman -Syu --noconfirm base-devel mpfr mpc gmp curl git cmake texinfo
pacman -S --noconfirm mingw-w64-x86_64-gcc
pacman -S --noconfirm mingw-w64-x86_64-cmake mingw-w64-x86_64-make mingw-w64-x86_64-libpng

mkdir /c/cross
cd /c/cross
mkdir /c/cross/out

export PREFIX="/c/cross/out"
export TARGET=sh4-elf

curl -L http://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.bz2 | tar xj
mkdir binutils-build
cd binutils-build
../binutils-$BINUTILS_VERSION/configure --target=${TARGET} --prefix=${PREFIX} --disable-nls --disable-shared --disable-multilib
make -j$(nproc)
make install

cd ..
curl -L http://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz | tar xJ
mkdir gcc-build
cd gcc-build
../gcc-$GCC_VERSION/configure --target=${TARGET} --prefix=${PREFIX} \
        --enable-languages=c,c++ \
        --with-newlib --without-headers --disable-hosted-libstdcxx \
        --disable-tls --disable-nls --disable-threads --disable-shared \
        --enable-libssp --disable-libvtv --disable-libada \
        --with-endian=big --enable-lto --with-multilib-list=m4-nofpu
make -j$(nproc) inhibit_libc=true all-gcc
make install-gcc

make -j$(nproc) inhibit_libc=true all-target-libgcc
make install-target-libgcc

cp /mingw64/bin/libiconv-2.dll ${PREFIX}/bin/
cp /mingw64/bin/libwinpthread-1.dll ${PREFIX}/bin/

cp /mingw64/bin/libmpc-3.dll ${PREFIX}/libexec/gcc/sh4-elf/$GCC_VERSION/
cp /mingw64/bin/libgmp-10.dll ${PREFIX}/libexec/gcc/sh4-elf/$GCC_VERSION/
cp /mingw64/bin/libisl-23.dll ${PREFIX}/libexec/gcc/sh4-elf/$GCC_VERSION/
cp /mingw64/bin/libmpfr-6.dll ${PREFIX}/libexec/gcc/sh4-elf/$GCC_VERSION/
cp /mingw64/bin/libzstd.dll ${PREFIX}/libexec/gcc/sh4-elf/$GCC_VERSION/
cp /mingw64/bin/libgcc_s_seh-1.dll ${PREFIX}/libexec/gcc/sh4-elf/$GCC_VERSION/
cp /mingw64/bin/libiconv-2.dll ${PREFIX}/libexec/gcc/sh4-elf/$GCC_VERSION/
cp /mingw64/bin/libwinpthread-1.dll ${PREFIX}/libexec/gcc/sh4-elf/$GCC_VERSION/

export PATH="${PREFIX}/bin:$PATH"
'@

$crossScriptPath = Join-Path $env:TEMP "cross-script.sh"
[System.IO.File]::WriteAllText($crossScriptPath, $gccScript, (New-Object System.Text.UTF8Encoding($false)))

Write-Output "Running GCC build script..."

# Run the GCC build script in MinGW64 shell
& "$msys2Root\mingw64.exe" bash "$crossScript"

# export SDK_DIR="/c/hollyhock-2/sdk"
# https://github.com/QBos07/newlib-cp2/tree/master