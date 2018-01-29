#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

[ "$1" != "" ] && NAME_MACHINE="$1"
[ "$2" != "" ] && ARCH="$2"
[ "$3" != "" ] && DE="$3" && NAME_DE="- ( $3 )"
PATH_2_KERNEL="$NAME_MACHINE"
[ "$4" != "" ] && NFS_ROOT="$4" 
IP_SRV="192.168.1.5"
[ "$5" != "" ] && IP_SRV="$5"

cat <<EOF 
==> FOR SYSLINUX WITH TFTP :
label ${ARCH}_$DE
menu label $NAME_MACHINE Arch Linux $ARCH $NAME_DE
kernel $PATH_2_KERNEL/boot/vmlinuz-linux
append initrd=$PATH_2_KERNEL/boot/initramfs-linux.img ip=:::::eth0:dhcp nfsroot=$IP_SRV:$NFS_ROOT/$PATH_2_KERNEL
text help
Boot Arch Linux $ARCH with $DE on network
endtext

label ${ARCH}_${DE}_fallback
menu label $NAME_MACHINE Arch Linux $ARCH $NAME_DE - Fallback Image
kernel $PATH_2_KERNEL/boot/vmlinuz-linux
append initrd=$PATH_2_KERNEL/boot/initramfs-linux-fallback.img ip=:::::eth0:dhcp nfsroot=$IP_SRV:$NFS_ROOT/$PATH_2_KERNEL
text help
Boot Arch Linux $ARCH Fallback image with $DE on network
endtext


EOF
# 	final_message="FOR SYSLINUX WITH TFTP :
# label $NAME_MACHINE
# menu label Arch Linux $ARCH - ( $DE )
# kernel $NAME_MACHINE/boot/vmlinuz-linux
# append initrd=$NAME_MACHINE/boot/initramfs-linux.img ip=:::::eth0:dhcp nfsroot=192.168.1.5:/pxe/$NAME_MACHINE
# 
# label $NAME_MACHINE
# menu label Arch Linux $ARCH - ( $DE ) - Fallback Image
# kernel $NAME_MACHINE/boot/vmlinuz-linux
# append initrd=$NAME_MACHINE/boot/initramfs-linux-fallback.img ip=:::::eth0:dhcp nfsroot=192.168.1.5:/pxe/$NAME_MACHINE"
