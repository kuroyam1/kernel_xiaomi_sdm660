#!/bin/bash

#
# Configure defualt value:
# CPU = use all cpu for build
# CHAT = chat telegram for push build. use id.
#
CPU=$(nproc --all)
SUBNAME="none"

sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git cmake binutils make bc bison \
    libssl-dev curl zip kmod cpio flex elfutils libssl-dev device-tree-compiler \
    ca-certificates python3 xz-utils libc6-dev aria2 ccache zstd lld clang wget \
    inetutils-tools libncurses5-dev libelf-dev gcc-multilib gcc-multilib libtool \
    binutils-aarch64-linux-gnu


#
# Add support cmd:
# --cpu= for cpu used to compile
# --key= for bot key used to push.
# --name= for custom subname of kernel
#
config() {

    arg1=${1}

    case ${1} in
        "--cpu="* )
            CPU="--cpu="
            CPU=${arg1#"$CPU"}
        ;;
        "--key="* )
            KEY="--key="
            KEY=${arg1#"$KEY"}
        ;;
        "--name="* )
            SUBNAME="--name="
            SUBNAME=${arg1#"$SUBNAME"}
        ;;
    esac
}

arg1=${1}
arg2=${2}
arg3=${3}

config ${1}
config ${2}
config ${3}

echo "Config for resource of environment done."
echo "CPU for build: $CPU"
echo "NAME of kernel: $SUBNAME"

# start build date
DATE=$(date +"%Y%m%d-%H%M")

# Compiler type
TOOLCHAIN_DIRECTORY="tc"

# Build defconfig
DEFCONFIG="lavender_defconfig"

# Check for compiler
if [ ! -d "$TOOLCHAIN_DIRECTORY" ]; then
	git clone --depth=1 https://gitlab.com/Project-Nexus/nexus-clang.git -b nexus-14 $TOOLCHAIN_DIRECTORY/custom-clang
fi

if [ -d "$TOOLCHAIN_DIRECTORY/custom-clang" ]; then
    echo -e "${bldgrn}"
    echo "clang is ready"
    echo -e "${txtrst}"
else
    echo -e "${red}"
    echo "Need to download clang"
    echo -e "${txtrst}"
    exit
fi

#
# Build start with clang
#
echo 'alias grep="/usr/bin/grep $GREP_OPTIONS"' >> ~/.bashrc
echo 'unset GREP_OPTIONS' >> ~/.bashrc
source ~/.bashrc

export PATH="$(pwd)/$TOOLCHAIN_DIRECTORY/custom-clang/bin:${PATH}"
make O=out CC=clang ARCH=arm64 $DEFCONFIG
make -j$CPU O=out \
			ARCH=arm64 \
			CC=clang \
			CROSS_COMPILE=aarch64-linux-gnu- \
			CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
			Image.gz-dtb


# Download anykernel for flash kernel
git clone --depth=1 https://github.com/binhvo7794/AnyKernel3 -b spes anykernel


if [ $SUBNAME == "none" ]; then
    SUBNAME=$DATE
fi

curl bashupload.com -T out/arch/arm64/boot/Image.gz-dtb
cd anykernel
zip -r9 ../Sus-$SUBNAME.zip * -x .git README.md *placeholder
#curl bashupload.com -T ../Sus-$SUBNAME.zip
cd ..
rm -rf anykernel
echo "The path of the kernel.zip is: $(pwd)/Sus-$SUBNAME.zip"

