#!/bin/bash
#
# This script builds the CM kernel and copies it to the Epic MTD device tree.
# If you are building outside of a CM tree, you must specify the path to your
# device tree.
#
#   export CMPATH=/path/to/your/cmrepo >> ~/.bashrc
#

#uncomment to add custom version string
#export KBUILD_BUILD_VERSION=""
DEFCONFIG_STRING=cyanogenmod_epicmtd_defconfig

# Shouldn't need to modify anything below here
. include/functions
find_toolchain

# Display Environment

echo "$1 $2 $3"

case "$1" in
	Clean)
		echo "************************************************************"
		echo "* Clean Kernel                                             *"
		echo "************************************************************"
		pushd Kernel
			make clean V=1 ARCH=arm CROSS_COMPILE=$TCPATH/$TOOLCHAIN_PREFIX 2>&1 | tee make.clean.out
		popd
		echo " Clean is done... "
		exit
		;;
	mrproper)
		echo "************************************************************"
		echo "* mrproper Kernel                                          *"
		echo "************************************************************"
		pushd Kernel
			make clean V=1 ARCH=arm CROSS_COMPILE=$TCPATH/$TOOLCHAIN_PREFIX 2>&1 | tee make.clean.out
			make mrproper 2>&1 | tee make.mrproper.out
		popd
		echo " mrproper is done... "
		exit
		;;
	distclean)
		echo "************************************************************"
		echo "* distclean Kernel                                         *"
		echo "************************************************************"
		pushd Kernel
			make clean V=1 ARCH=arm CROSS_COMPILE=$TCPATH/$TOOLCHAIN_PREFIX 2>&1 | tee make.clean.out
			make distclean 2>&1 | tee make.distclean.out
		popd
		echo " distclean is done... "
		exit
		;;
	*)
		PROJECT_NAME=SPH-D700
		HW_BOARD_REV="03"
		;;
esac

if [ "$CPU_JOB_NUM" = "" ] ; then
    # Detect number of threads
    if [ -f /proc/cpuinfo ]; then
        CPU_JOB_NUM=$(cat /proc/cpuinfo  |grep ^processor |wc -l)
    else
	CPU_JOB_NUM=4
    fi
fi

TARGET_LOCALE="vzw"

TOOLCHAIN_PREFIX=arm-eabi-

KERNEL_BUILD_DIR=`pwd`/Kernel

export PRJROOT=$PWD
export PROJECT_NAME
export HW_BOARD_REV

export LD_LIBRARY_PATH=.:${TCPATH}/../lib

echo "************************************************************"
echo "* EXPORT VARIABLE                                          *"
echo "************************************************************"
echo "PRJROOT=$PRJROOT"
echo "PROJECT_NAME=$PROJECT_NAME"
echo "HW_BOARD_REV=$HW_BOARD_REV"
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
echo "************************************************************"

BUILD_MODULE()
{
	echo "************************************************************"
	echo "* BUILD_MODULE                                             *"
	echo "************************************************************"
	echo
	pushd Kernel
		make ARCH=arm modules
	popd
}

CLEAN_ZIMAGE()
{
	echo "************************************************************"
	echo "* Removing old zImage                                      *"
	echo "************************************************************"
	rm -f `pwd`/Kernel/arch/arm/boot/zImage
	echo "* zImage removed"
	echo "************************************************************"
	echo
}

BUILD_KERNEL()
{
	echo "************************************************************"
	echo "* BUILD_KERNEL                                             *"
	echo "************************************************************"
	echo
	pushd $KERNEL_BUILD_DIR
		export KDIR=`pwd`
		#make clean mrproper
		make ARCH=arm $DEFCONFIG_STRING
		make -j$CPU_JOB_NUM ARCH=arm CROSS_COMPILE=$TCPATH/$TOOLCHAIN_PREFIX 2>&1 | tee make.out
#		make V=1 -j$CPU_JOB_NUM ARCH=arm CROSS_COMPILE=$TCPATH/$TOOLCHAIN_PREFIX 2>&1 | tee make.out
                echo "Copying zImage to $DPATH/kernel"
		cp arch/arm/boot/zImage $DPATH/kernel
                rm -f $DPATH/modules/*.ko
                for kmod in `find -name '*.ko'`; do
                    echo "Copying $kmod to $DPATH/modules/"
                    cp $kmod $DPATH/modules/
                done
	popd
}

# print title
PRINT_USAGE()
{
	echo "************************************************************"
	echo "* PLEASE TRY AGAIN                                         *"
	echo "************************************************************"
	echo
}

PRINT_TITLE()
{
	echo
	echo "************************************************************"
	echo "* MAKE PACKAGES                                            *"
	echo "************************************************************"
	echo "* 1. kernel : zImage"
	echo "* 2. modules"
	echo "************************************************************"
}

##############################################################
#                   MAIN FUNCTION                            #
##############################################################
if [ $# -gt 3 ]
then
	echo
	echo "************************************************************"
	echo "* Option Error                                             *"
	PRINT_USAGE
	exit 1
fi

START_TIME=`date +%s`
PRINT_TITLE
#BUILD_MODULE
CLEAN_ZIMAGE
BUILD_KERNEL
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo "Total compile time is $ELAPSED_TIME seconds"
