#!/bin/bash

# testf() {
# 	PS1="[\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]]\\$ \[\033[s\]\[\033[1;\$((COLUMNS-8))f\]\$(date +%T)\[\033[u\]"
# }
# 
# 
# # while [ 1 ]; do 
# 	testf &
# # done
# exit
# [ "$0" == "./launchInstall.sh" ] && REP_SCRIPT=`pwd` || REP_SCRIPT=`echo $0 | sed 's/\/launchInstall.sh//g'`
# cd "$REP_SCRIPT"
# source files/futil
# source files/fr.trans

DIR_ARCHISO="/tmp/archiso"
DIR_SCRIPT="/media/srv/scripts/anarchic"
DIR_RESULT="/tmp"
ISO_NAME="anarchic.iso"
NAME="Anarchic"
PACKAGE_BOTH="\nsed\ngrep\niproute"
NB_COLUMS=$(($( echo $NAME | wc -c )-1))

# echo $NB_COLUMS
# exit

# Création du dossier de travail
[ ! -e $DIR_ARCHISO ] && mkdir $DIR_ARCHISO

# Copie des fichiers de l'iso dans le dossier de travail ( /tmp/archiso )
[ ! -e $DIR_ARCHISO/releng ] && cp -r /usr/share/archiso/configs/releng/ $DIR_ARCHISO

cd $DIR_ARCHISO/releng/

# Suppression des fichiers pour recompiler
# ( Décommenter pour réinstaller tout les paquets !)...
#
# rm -v work/build.make_* 
# rm -v work/build.make_basefs_i686
# rm -v work/build.make_basefs_x86_64
rm -v work/build.make_boot_extra_x86_64
rm -v work/build.make_boot_i686
rm -v work/build.make_boot_x86_64
rm -v work/build.make_customize_airootfs_i686
rm -v work/build.make_customize_airootfs_x86_64
rm -v work/build.make_efiboot_x86_64
rm -v work/build.make_efi_x86_64
rm -v work/build.make_isolinux_x86_64
rm -v work/build.make_iso_x86_64
rm -v work/build.make_syslinux_x86_64
rm -v  work/build.make_packages_efi_x86_64    
# rm -v  work/build.make_packages_i686          
# rm -v  work/build.make_packages_x86_64        
rm -v  work/build.make_pacman_conf_x86_64     
rm -v  work/build.make_prepare_i686           
rm -v  work/build.make_prepare_x86_64         
# rm -v  work/build.make_setup_mkinitcpio_i686  
# rm -v  work/build.make_setup_mkinitcpio_x86_64
 



#[ ! -e $DIR_ARCHISO/releng/airootfs/etc/skel ] && mkdir $DIR_ARCHISO/releng/airootfs/etc/skel

# Normal conf
# echo "#
# # ~/.bash_profile
# #
# 
# [[ -f ~/.bashrc ]] && . ~/.bashrc
# 
# [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]]
# 
# bash /initialise " > $DIR_ARCHISO/releng/airootfs/etc/skel/.bash_profile


# Récupération de la liste des paquets puis...
cp /usr/share/archiso/configs/releng/packages.both $DIR_ARCHISO/releng/
# ... ajout des paquets nécessaires
echo -e "$PACKAGE_BOTH" >> $DIR_ARCHISO/releng/packages.both

# Copie de mon propre bashrc et bash_profile
cp -R $DIR_SCRIPT/iso/skel $DIR_ARCHISO/releng/airootfs/etc/
# Ajout des commandes pour lancer le script dans bash_profile 
echo "#CONF SRV
# mkdir -p /media/srv
# ! mountpoint -q /media/srv && mount 192.168.1.5:/ /media/srv 
# bash $DIR_SCRIPT/iso/initialise 

#CONF CD
bash /initialise
" >> $DIR_ARCHISO/releng/airootfs/etc/skel/.bash_profile

# Useless : Affiche $NAME en haut à droite lorsqu'on arrive sur un nouveau prompt...
sed -i "s/TEXT_TOCHANGE/$NAME/" $DIR_ARCHISO/releng/airootfs/etc/skel/.bashrc
sed -i "s/COL_TOCHANGE/$NB_COLUMS/" $DIR_ARCHISO/releng/airootfs/etc/skel/.bashrc

# Remplacement de zsh par bash comme interpreteur par défaut
# nano /tmp/archiso/releng/airootfs/root/customize_airootfs.sh  
sed -i "s/\/usr\/bin\/zsh/\/bin\/bash/" $DIR_ARCHISO/releng/airootfs/root/customize_airootfs.sh

# Copie des fichiers de l'iso ( le script qui lance l'installation et un background )
cp $DIR_SCRIPT/iso/initialise $DIR_ARCHISO/releng/airootfs/
cp -R $DIR_SCRIPT/iso/splash.png  $DIR_ARCHISO/releng/syslinux/splash.png

# Copie des fichiers de l'installation...
cp -R $DIR_SCRIPT/{pacinstall.sh,files/,launchInstall.sh}  $DIR_ARCHISO/releng/airootfs/root/

# Construction de l'iso
./build.sh -v
# Copie de la nouvelle iso dans /tmp
cp -v $DIR_ARCHISO/releng/out/* $DIR_RESULT/$ISO_NAME


# echo "/usr/bin/zsh" |  sed "s/\/usr\/bin\/zsh/\/bin\/bash/"
# PS1=\"[\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]]\\$ \[\033[s\]\[\033[1;\\$((COLUMNS-$NB_COLUMS))f\]\\$NAME\[\033[u\]" 