#!/usr/bin/env bash

#packages required to edit
sudo apt-get install -qq squashfs-tools genisoimage

#downloading the ISO to edit
bash Download.sh
mv *.iso linuxinator.iso

#exit on any error
set -e

mkdir mnt
#Mount the ISO 
sudo mount -o loop linuxinator.iso mnt/
#Extract .iso contents into dir 'extract-cd' 
mkdir extract-cd
sudo rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd
#Extract the SquashFS filesystem 
sudo unsquashfs -n mnt/casper/filesystem.squashfs
sudo mv squashfs-root edit

#repacking
sudo chmod +w extract-cd/casper/filesystem.manifest
sudo su <<HERE
chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' > extract-cd/casper/filesystem.manifest <<EOF
exit
EOF
HERE
sudo cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop
sudo sed -i '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop
sudo sed -i '/casper/d' extract-cd/casper/filesystem.manifest-desktop
#sudo rm extract-cd/casper/filesystem.squashfs
sudo mksquashfs edit extract-cd/casper/filesystem.squashfs -noappend
echo ">>> Recomputing MD5 sums"
sudo su <<HERE
( cd extract-cd/ && find . -type f -not -name md5sum.txt -not -path '*/isolinux/*' -print0 | xargs -0 -- md5sum > md5sum.txt )
exit
HERE
cd extract-cd 	

sudo mkisofs \
    -V "Linuxinator \
    -r -cache-inodes -J -l \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
	-o ../Linuxinator.iso .
