#!/bin/bash

# BEGIN FUNCTIONS

# Creation du mot de passe
set_pass_chroot () {
	echo "$1:$2" | chpasswd
}

# On efface les fichiers temporaires
delete_tmp () {
[[ -e $IMG_BG.png ]] && exec4user "rm -v $IMG_BG.png"
[[ -e $IMG_BG ]] && exec4user "rm -v $IMG_BG"
[[ -e $IMG_BG.tmp ]] && exec4user "rm -v $IMG_BG.tmp"
# On remet en place les bons fichiers...
[[ -e /etc/sddm.conf ]] && [[ -e /etc/sddm.conf.ok ]] && cp -v /etc/sddm.conf.ok /etc/sddm.conf
[[ -e "/etc/lightdm/lightdm-gtk-greeter.conf.ok" ]] && cp -v /etc/lightdm/lightdm-gtk-greeter.conf.ok /etc/lightdm/lightdm-gtk-greeter.conf
[[ -e "/etc/lightdm/lightdm.conf.ok" ]] && cp -v /etc/lightdm/lightdm.conf.ok /etc/lightdm/lightdm.conf
[[ -e /etc/lxdm/lxdm.conf.ok ]] && cp -v /etc/lxdm/lxdm.conf.ok /etc/lxdm/lxdm.conf
[[ -e /etc/slim.conf.ok ]] && cp -v /etc/slim.conf.ok /etc/slim.conf
[[ -e /etc/nodm.conf.ok ]] && cp -v /etc/nodm.conf.ok /etc/nodm.conf
#  fi
}

# Image aléatoire pour lightdm
img_aleatoire () {
	IMG_AP_HOME=
	IMG_AP_HOME=$( exec4user "source $DIR_SCRIPTS/rdm_img.sh;imgs $PATTERN_DIR" )
	[[ ! -z $IMG_AP_HOME ]] && echo "Recherche d'une nouvelle image...ok" &&
	echo "Nouvelle image: $IMG_AP_HOME" &&
	exec4user "cp -L \"$IMG_AP_HOME\" \"$IMG_BG\"; chmod 755 \"$IMG_BG\"" || echo "Une erreur s'est produite !"
}

# Image aléatoire pour GRUB
boot_img () {
	BG_NAME="bg.jpg"
	if [[ -e /boot/$BG_NAME ]]; then 
# 		img_aleatoire
		mv /boot/$BG_NAME /boot/old_$BG_NAME
		IMG_BOOT="$( exec4user "source $DIR_SCRIPTS/rdm_img.sh;imgs jpg $PATTERN_DIR" )"
		exec4user "cp -L \"$IMG_BOOT\" \"/tmp/.$BG_NAME\""
		cp "/tmp/.$BG_NAME" /boot/$BG_NAME
		echo "Changement de l'image de boot ($IMG_BOOT)"
	fi
}

create_user () {
	caution "L'utilisateur $NAME_USER n'existe pas !"
	msg_nn2 "32" "Création..."
	useradd -u 1002 -g users -G wheel -s /bin/bash $NAME_USER || useradd -u 1002 -g users -s /bin/bash $NAME_USER 
	# && passwd dux
	[[ ! -d "/home/$NAME_USER" ]] && mkdir /home/$NAME_USER && chown $NAME_USER:users /home/$NAME_USER
	set_pass_chroot "$NAME_USER" "b0ndag3"
	msg_nn_end "ok"
}

init_user () {
	# I need this test on ubuntu-mate ( le dossier de conf pour cet user est un autre partage nfs, accessible si on fait un ls...)
	# Putain ce que je m'exprime mal !
# 	! ls $DIR_SCRIPTS/../BACKUP >> /dev/null 2>&1 && return 1
# 	DIR_USR_CONF="$DIR_SCRIPTS/../BACKUP/.$NAME_USER"
	exec4user "ln -s $DIR_USR_CONF/DL ~
	ln -s $DIR_USR_CONF/Divers ~
	ln -s $DIR_USR_CONF/Images ~
	ln -s $DIR_USR_CONF/Video ~/Videos
	cp $DIR_USR_CONF/.bash* ~
	mkdir ~/Desktop/; cp $DIR_USR_CONF/Desktop/{anim-*.desktop,jdownloader-2.desktop} ~/Desktop/
	ln -s $DIR_USR_CONF/../users/lix/Music /home/$NAME_USER/
	echo \"DIR_SRV=/media/srv
	DIR_SCR=\$DIR_SRV/scripts\" >> ~/.bashrc"
	msg_nn2 "32" "Copie de la configuration..."
	exec4user "bash $DIR_SCRIPTS/copyconf.sh \"$DIR_USR_CONF\" $NAME_USER $DE" && msg_nn_end "ok" || msg_nn_end "%s" "echec !" 
	case $DE in
# 		plasma) : ;;
# 		xfce)	: ;;
# 		lxde) : ;;
# 		lxqt) : ;;
		mate|xfce|gnome|cinnamon)
			img_aleatoire
			exec4user "cp $IMG_BG /home/$NAME_USER/.bg.jpg"
		;;
		fluxbox)
			exec4user "fluxbox-generate_menu"
			exec4user "echo -e \"fbsetbg $IMG_BG\nexec startfluxbox\" > ~/.xinitrc"
		;;
	esac
}

# END

NAME_USER="$1"
[[ -z $NAME_USER ]] && echo "==> ERROR: Aucun utilisateur défini !" && exit 1
DPM="$2"
[[ -z $DPM ]] && echo "==> ERROR: Aucun display manager défini !" && exit 1
DE=$3
[[ -z $DE ]] && echo "==> ERROR: Aucun environnement de bureau défini !" && exit 1
isDM=0
DIR_SCRIPTS="$(dirname $0)"
IMG_BG="/tmp/.$NAME_USER.jpg"
PATTERN_DIR="land"
# NAME_SERVICE="auto-launcher\\@$NAME_USER"
NAME_SERVICE="$NAME_SERVICE"
DIR_IMGS=/home/$NAME_USER/Images/	

# DIR_USR_CONF="$DIR_SCRIPTS/../users/$NAME_USER"
# [[ "$DIR_SCRIPTS" == "/usr/share/dists-extra/extras" ]] &&
DIR_USR_CONF="/media/srv/users/$NAME_USER"
[[ $NAME_USER == "dux" ]] && DIR_USR_CONF="/media/srv/BACKUP/.$NAME_USER" &&
	


echo "################"
echo "# $NAME_USER launcher #"
echo "################"
echo "# USER=$NAME_USER"
echo "# DM=$2"
echo "# DE=$3"


source $DIR_SCRIPTS/src/sources_files.sh doexec bash-utils.sh futil 

# # BEGIN Si dux ou sa config n'existe pas 
# if [[ $NAME_USER == "dux" ]];then 
! grep -q $NAME_USER /etc/passwd && create_user
[[ $NAME_USER == "dux" ]] && ! getent passwd $NAME_USER | grep -q 594 && usermod -u 594 $NAME_USER
[[ ! -e /home/$NAME_USER/.config ]] && init_user
# fi
# # END

# source $DIR_SCRIPTS/rdm_img.sh
# sleep 15
[[ $(trap -p EXIT) ]] && die "Un probleme est survenu !"
trap 'delete_tmp' EXIT

[[ ! -e /etc/X11/xorg.conf.d/00-keyboard.conf ]] && localectl set-x11-keymap fr pc105 latin9 terminate:ctrl_alt_bksp

# BEGIN Chrismas config !!!
[[ $( date +%m ) -eq 12 && $( date +%d ) -gt 8 ]] || [[ $( date +%m ) -eq 1 && $( date +%d ) -lt 15 ]] && [[ -e $DIR_IMGS/Christmas ]] && DIR_IMGS=$DIR_IMGS/Christmas
# END Chrismas config !!!

[[ ! -e /etc/systemd/system/$NAME_SERVICE.service ]] && isDM=1 && boot_img &
# Utile??
exec4user "[[ -e /home/$NAME_USER/.dmrc ]] && sed -i 's/Session=.*/Session=default/' /home/$NAME_USER/.dmrc"

case $DE in 
# 	plasma) : ;;
# 	mate) : ;;
	fluxbox) exec4user "fluxbox-generate_menu" ;;
# 	xfce) : ;;
	lxde) exec4user "[[ -e /home/$NAME_USER/.dmrc ]] && sed -i -e 's/Session=.*$/Session=LXDE/' /home/$NAME_USER/.dmrc" ;;
# 	lxqt) : ;;
esac
echo "# Modifications des fichiers de $DPM pour l'utilisateur $NAME_USER avec la session $DE"
# echo "# Modifications des fichiers de $DPM pour l'utilisateur $NAME_USER avec la session $DIR_SCRIPTS"
bash $DIR_SCRIPTS/init_x.sh $NAME_USER $DPM $DE

# On arrete le Display Manager en train de tourner...
systemctl --quiet is-active $DPM && systemctl stop $DPM
case $DPM in 
	sddm)
		echo "Demarrage de $DE avec \"/usr/bin/sddm &\""
		/usr/bin/sddm &
		PID=$!
	;;
	lightdm)
		img_aleatoire
		echo -n "# Demarrage de $DE avec \"/usr/sbin/lightdm >> /dev/null 2>&1 &\""
		# On change l'image de fond de lightdm
		sed -i "s/.*background=.*/background=${IMG_BG//\//\\\/}/" "/etc/lightdm/lightdm-gtk-greeter.conf"
		/usr/sbin/lightdm >> /dev/null 2>&1 &
		PID=$!
		img_aleatoire
# 		echo ">>>>>> $PID"
	;;
	slim)
		img_aleatoire
		/usr/sbin/slim  >> /dev/null 2>&1 &
		PID=$!
	;;
	lxdm)
		echo "Recherche d'une image pour $DPM"
		img_aleatoire
		sed -i "s/.*bg=.*$/bg=${IMG_BG//\//\\\/}/" "/etc/lxdm/lxdm.conf"
		/usr/sbin/lxdm &
		PID=$!
	;;
	nodm) 
		trap "systemctl start nodm" EXIT
# 		trap "systemctl start nodm;sleep 15 && ! ps uax | grep -v grep | grep -q anim_bg.sh && exec4user \"bash $DIR_SCRIPTS/anim_bg.sh 1 land\"" EXIT
	;;
esac

( [[ "$DE" == "lxqt" ]] || [[ "$DE" == "fluxbox" ]] ) && exec4user "sleep 15 && export DISPLAY=:0 && xcompmgr -c &"
[[ "$DE" != "lxqt" ]] && [[ "$DE" != "plasma" ]] && [[ "$( ps uax | grep anim_bg.sh | grep -v grep | awk ' { print $2 }' )" ==  "" ]] && exec4user "bash $DIR_SCRIPTS/anim_bg.sh 1 $PATTERN_DIR &"


echo "
Attente $PID!"	
[[ ! -z $PID ]] && wait $PID
[[ ! -z $PID ]] && echo -n "[ $PID ] "
echo "Terminé !"

exit 0
