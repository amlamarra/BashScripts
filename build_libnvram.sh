#!/usr/bin/env bash
# This is to make building & testing libnvram.so for Firmadyne-emulated firmware faster

# Set defaults here
id=3
arch=mipseb

[ "$1" ] && id="$1"
[ "$2" ] && arch="$2"

if [[ "$arch" == "arm" ]]; then
    arch=armel
    toolchain=arm-linux-musleabi
else
    toolchain="$arch"
fi

echo "Building $arch..."
make clean
export CC="/opt/cross/$toolchain/bin/$toolchain-gcc"
make
cp libnvram.so "$HOME/firmadyne/binaries/libnvram.so.$arch"

echo -e "\nMounting device $id..."
(   
    cd ~/firmadyne || exit 1
    sudo ~/firmadyne/scripts/mount.sh "$id"
)

echo -e "\nCopying to device filesystem..."
if [ -d "$HOME/firmadyne/scratch/${id}/image/firmadyne" ]; then
    sudo cp libnvram.so "$HOME/firmadyne/scratch/${id}/image/firmadyne"
fi

echo -e "\nUnmounting device $id..."
(
    cd ~/firmadyne || exit 1
    sudo ~/firmadyne/scripts/umount.sh "$id"
)

echo -e "\nCleaning up..."
make clean
