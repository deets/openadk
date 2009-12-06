#!/usr/bin/env bash

grubinstall=1
filesystem=ext2

while getopts "f:t:in" option
do
	case $option in
		f)
		filesystem=$OPTARG
		;;
		t)
		emul=$OPTARG
		;;
		i)
		initramfs=1
		;;
		n)
		grubinstall=0
		;;
		*)
		printf "Option not recognized\n"
		exit 1
		;;
	esac
done
shift $(($OPTIND - 1))

if [ $(id -u) -ne 0 ];then
	printf "Installation is only possible as root\n"
	exit 1
fi

printf "Checking if grub is installed"
grub=$(which grub)

if [ ! -z $grub -a -x $grub ];then
	printf "...okay\n"
else
	printf "...failed\n"
	exit 1
fi

printf "Checking if parted is installed"
parted=$(which parted)

if [ ! -z $parted -a -x $parted ];then
	printf "...okay\n"
else
	printf "...failed\n"
	exit 1
fi

printf "Checking if qemu-img is installed"
qimg=$(which qemu-img)

if [ ! -z $qimg -a -x $qimg ];then
	printf "...okay\n"
else
	printf "...failed\n"
	exit 1
fi

if [ -z $1 ];then
	printf "Please give the name of the image file\n"
	exit 1
fi	

if [ -z $initramfs ];then
	if [ -z $2 ];then
		printf "Please give the name of the openadk archive file\n"
		exit 1
	fi	
else
	if [ -z $2 ];then
		printf "Please give the full path prefix to kernel/initramfs\n"
		exit 1
	fi
fi


printf "Generate qemu image\n"
$qimg create -f raw $1 512M >/dev/null

printf "Creating filesystem $filesystem\n"

printf "Create partition and filesystem\n"
$parted -s $1 mklabel msdos
$parted -s $1 mkpart primary ext2 0 100%
$parted -s $1 set 1 boot on

dd if=$1 of=mbr bs=16384 count=1 2>/dev/null
dd if=$1 skip=16384 of=$1.new 2>/dev/null

if [ "$filesystem" = "ext2" -o "$filesystem" = "ext3" -o "$filesystem" = "ext4" ];then
	mkfsopts=-F
fi

mkfs.$filesystem $mkfsopts ${1}.new >/dev/null

if [ $? -eq 0 ];then
	printf "Successfully created partition\n"
	#$parted $1 print
else
	printf "Partition creation failed, Exiting.\n"
	exit 1
fi

cat mbr ${1}.new > $1
rm ${1}.new 
rm mbr

tmp=$(mktemp -d)

mount -o loop,offset=16384 -t $filesystem $1 $tmp
#mount -o loop -t $filesystem $1 $tmp

if [ -z $initramfs ];then
	printf "Extracting install archive\n"
	tar -C $tmp -xzpf $2 
	printf "Fixing permissions\n"
	chmod 1777 $tmp/tmp
	chmod 4755 $tmp/bin/busybox
else
	printf "Copying kernel/initramfs\n"
	mkdir $tmp/boot $tmp/dev
	cp $2-kernel $tmp/boot/kernel
	cp $2-initramfs $tmp/boot/initramfs
fi

if [ $grubinstall -eq 1 ];then
printf "Copying grub files\n"
mkdir $tmp/boot/grub
cp /boot/grub/stage1 $tmp/boot/grub
cp /boot/grub/stage2 $tmp/boot/grub
cp /boot/grub/e2fs_stage1_5 $tmp/boot/grub

if [ -z $initramfs ];then
cat << EOF > $tmp/boot/grub/menu.lst
serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
terminal --timeout=2 serial console
timeout 2
default 0
hiddenmenu
title linux
root (hd0,0)
kernel /boot/kernel root=/dev/sda1 init=/init console=ttyS0,115200 console=tty0 panic=10 rw
EOF
else
cat << EOF > $tmp/boot/grub/menu.lst
serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
terminal --timeout=2 serial console
timeout 4
default 0
hiddenmenu
title linux
root (hd0,0)
kernel /boot/kernel root=/dev/sda1 console=ttyS0,115200 console=tty0 rw
initrd /boot/initramfs
EOF
fi

printf "Installing Grub bootloader\n"
$grub --batch --no-curses --no-floppy --device-map=/dev/null >/dev/null << EOF
device (hd0) $1
root (hd0,0)
setup (hd0)
quit
EOF

fi

printf "Creating device nodes\n"
mknod -m 666 $tmp/dev/zero c 1 5
mknod -m 666 $tmp/dev/null c 1 3
mknod -m 622 $tmp/dev/console c 5 1
mknod -m 666 $tmp/dev/tty c 5 0
mknod -m 666 $tmp/dev/tty0 c 4 0
mknod -m 660 $tmp/dev/hda b 3 0
mknod -m 660 $tmp/dev/hda1 b 3 1
mknod -m 666 $tmp/dev/ttyS0 c 4 64

umount $tmp

printf "Successfully installed.\n"
printf "Be sure $1 is writable for the user which use qemu\n"
exit 0
