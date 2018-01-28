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
		IMG_BOOT="$( exec4user "source $DIR_SCRIPTS/rdm_img.sh;imgs $PATTERN_DIR" )"
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
DIR_SCRIPTS="$(dirname $0)/.."
IMG_BG="/tmp/.$NAME_USER.jpg"
PATTERN_DIR="land"
# NAME_SERVICE="auto-launcher\\@$NAME_USER"
NAME_SERVICE="$NAME_SERVICE"
DIR_IMGS=/home/$NAME_USER/Images/	

	
DIR_USR_CONF="$DIR_SCRIPTS/../users/$NAME_USER"
[[ $NAME_USER == "dux" ]] && DIR_USR_CONF="$DIR_SCRIPTS/../BACKUP/.$NAME_USER"


echo "################"
echo "# Dux launcher #"
echo "################"
echo "# USER=$NAME_USER"
echo "# DM=$2"
echo "# DE=$3"


source $DIR_SCRIPTS/src/sources_files.sh doexec bash-utils.sh futil 

# fii=$( imgs)
# 
# echo $fii
# # img_aleatoire
# die "$fii"
# $DIR_SCRIPTS/futil
#source $DIR_SCRIPTS/rdm_img.sh

# # BEGIN Si dux ou sa config n'existe pas 
# if [[ $NAME_USER == "dux" ]];then 
! grep -q $NAME_USER /etc/passwd && create_user
[[ $NAME_USER == "dux" ]] && ! getent passwd $NAME_USER | grep -q 1002 && usermod -u 1002 $NAME_USER
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
# if [[ ! -e /etc/systemd/system/$NAME_SERVICE.service ]]; then
#     isDM=1
#     boot_img &
# fi

# if [[ "$DE" != "lxde" ]] || [[ "$DE" != "lxqt" ]]; then
# 	exec4user "[ -e ~/.config/autostart/lxde-slide.desktop ] && mv ~/.config/autostart/lxde-slide.desktop ~/.config/autostart/lxde-slide.desktop_"
# fi
exec4user "[[ -e /home/$NAME_USER/.dmrc ]] && sed -i 's/Session=.*/Session=default/' /home/$NAME_USER/.dmrc"

case $DE in 
	plasma) 
# 		# Changement du fond d'écran de base qui revient souvent...
# 		if ! exec4user "cat ~/.config/plasma-org.kde.plasma.desktop-appletsrc" | grep "\[org.kde.image\]\[General\]"; then
# 			i=0;
# 			j=0;
# 			while read -r; do
# 				i=$((i+1));
# 				[[ $REPLY =~ Containments ]] && j=$((j+1)) && netw[$j]=$REPLY 
# 				[[ $REPLY =~ org.kde.desktopcontainment ]] && ctn=${netw[$j]} && j=$((i+2))
# 				[[ $j -eq $i ]] && echo "
# $ctn[Wallpaper][org.kde.image][General]
# FillMode=2
# Image=file:///media/srv/BACKUP/.dux/Images/Hogtied/037_3.jpg
# " >> /tmp/plasma-org.kde.plasma.desktop-appletsrc
# 				echo $REPLY >> /tmp/plasma-org.kde.plasma.desktop-appletsrc
# 				echo "$REPLY"
# 			done < <(exec4user "cat ~/.config/plasma-org.kde.plasma.desktop-appletsrc")
# 			exec4user "cp /tmp/plasma-org.kde.plasma.desktop-appletsrc ~/.config/plasma-org.kde.plasma.desktop-appletsrc"
# 		fi
		:
	;;
	mate) : ;;
	fluxbox) exec4user "fluxbox-generate_menu";
# 		exec4user "echo -e \"fbsetbg $IMG_BG\nexec startfluxbox\" > ~/.xinitrc"
# 		[[ "$( ps uax | grep anim_bg.sh | grep -v grep | awk ' { print $2 }' )" ==  "" ]] && exec4user "bash $DIR_SCRIPTS/anim_bg.sh 1 land &"
# 		export DISPLAY=:0
# 		exec4user "export DISPLAY=:0 && xcompmgr -c &"
	;;
	xfce) : ;;
	lxde) :
		exec4user "[[ -e /home/$NAME_USER/.dmrc ]] && sed -i -e 's/Session=.*$/Session=LXDE/' /home/$NAME_USER/.dmrc" ;;
	lxqt) :
# 		sed -i.backup -e "s/^Session=/Session=lxqt.desktop #/" /etc/sddm.conf
# 		exec4user "mv ~/.config/autostart/lxde-slide.desktop_ ~/.config/autostart/lxde-slide.desktop"
	;;
esac
echo "# Modifications des fichiers de $DPM pour l'utilisateur $NAME_USER avec la session $DE"
bash $DIR_SCRIPTS/extras/init_x.sh $NAME_USER $DPM $DE

# On arrete le Display Manager en train de tourner...
systemctl --quiet is-active $DPM && systemctl stop $DPM
case $DPM in 
	sddm)
			echo "Demarrage de $DE avec \"/usr/bin/sddm &\""
			/usr/bin/sddm &
			PID=$!
# 		if (( $isDM )); then
# # 			delete_tmp
# 		else
# 			echo "Demarrage de $DE avec \"systemctl restart sddm\" !"
# 			systemctl restart sddm
# 			
# 			ping -q -c 2 "192.168.1.5" >/dev/null 2>&1
# 			if [ ! $? -eq 0 ]; then 
# 				exit
# 			fi
# 			sleep 30
# 		fi
	;;
	lightdm)
		img_aleatoire
		echo -n "# Demarrage de $DE avec \"/usr/sbin/lightdm >> /dev/null 2>&1 &\""
# 		if (( $isDM )); then
# 			echo "\"/usr/bin/lightdm -c /etc/lightdm/lightdm.conf.$NAME_USER >> /dev/null 2>&1\" !"
# # 			cp -v $IMG_BG /usr/share/pixmaps/
# 			sed -i "s/.*autologin-user=.*/autologin-user=$NAME_USER/" "/etc/lightdm/lightdm.conf.$NAME_USER"
# 			sed -i "s/.*autologin-session=.*/autologin-session=$DE.desktop/" "/etc/lightdm/lightdm.conf.$NAME_USER"
# 			sed -i "s/.*autologin-user-timeout=.*/autologin-user-timeout=10/" "/etc/lightdm/lightdm.conf.$NAME_USER"
# 			sed -i "s/.*background=.*/background=${IMG_BG//\//\\\/}/" "/etc/lightdm/lightdm-gtk-greeter.conf"
# # 			decompte 20 "Lancement dans %s"
# 			/usr/sbin/lightdm -c /etc/lightdm/lightdm.conf.$NAME_USER >> /dev/null 2>&1 &
# 			PID=$!
# 		else
# 			echo "\"systemctl restart lightdm\" !"
# 			sed -i "s/.*autologin-user=.*/autologin-user=$NAME_USER/" "/etc/lightdm/lightdm.conf"
# 			sed -i "s/.*autologin-user-timeout=.*/autologin-user-timeout=10/" "/etc/lightdm/lightdm.conf"
# 			sed -i "s/.*background=.*/background=${IMG_BG//\//\\\/}/" "/etc/lightdm/lightdm-gtk-greeter.conf"
# 	 		systemctl restart lightdm
# 		fi
# 			systemctl is-active lightdm && systemctl stop lightdm 
			sed -i "s/.*background=.*/background=${IMG_BG//\//\\\/}/" "/etc/lightdm/lightdm-gtk-greeter.conf"
			
# 			if systemctl is-enabled $NAME_SERVICE; then
# 				systemctl restart lightdm
# 			
# 			else
# 				echo "$NAME_SERVICE --> $isDM"
# 			
# 			fi
			/usr/sbin/lightdm >> /dev/null 2>&1 &
			PID=$!
			img_aleatoire
			echo ">>>>>> $PID"
	;;
	slim)
		img_aleatoire
                    /usr/sbin/slim  >> /dev/null 2>&1 &
                    PID=$!
# 		if (( $isDM )); then
#                     /usr/sbin/slim  >> /dev/null 2>&1 &
#                     PID=$!
# 		else
# 			systemctl restart slim
# 		fi
# 		sleep 5
# 		cp /etc/slim.conf.ok /etc/slim.conf
	;;
	lxdm)
		echo "Recherche d'une image pour $DPM"
		img_aleatoire
		sed -i "s/.*bg=.*$/bg=${IMG_BG//\//\\\/}/" "/etc/lxdm/lxdm.conf"
# 		echo "sed -i \"s/#[[:space:]]*bg=.*$/bg=${IMG_BG//\//\\\/}/" "/etc/lxdm/lxdm.conf\""
# 		if (( $isDM )); then
		/usr/sbin/lxdm &
		PID=$!
# 		sleep 5
#                     delete_tmp
# 		else
# 			systemctl restart lxdm
# 			sleep 5
# 		fi
	;;
	nodm) 
		trap "systemctl start nodm" EXIT
# 		trap "systemctl start nodm;sleep 15 && ! ps uax | grep -v grep | grep -q anim_bg.sh && exec4user \"bash $DIR_SCRIPTS/anim_bg.sh 1 land\"" EXIT
	;;
esac

( [[ "$DE" == "lxqt" ]] || [[ "$DE" == "fluxbox" ]] ) && exec4user "sleep 15 && export DISPLAY=:0 && xcompmgr -c &"
[[ "$DE" != "lxqt" ]] && [[ "$DE" != "plasma" ]] && [[ "$( ps uax | grep anim_bg.sh | grep -v grep | awk ' { print $2 }' )" ==  "" ]] && exec4user "bash $DIR_SCRIPTS/anim_bg.sh 1 $PATTERN_DIR &"


# if (( $isDM )); then
	echo "
	Attente $PID!"	
	[[ ! -z $PID ]] && wait $PID
	[[ ! -z $PID ]] && echo -n "[ $PID ] "
# else
#  :
# fi
# ps aux | grep anim
# sleep 70
echo "Terminé !"


# if [[ "$DE" == "plasma" ]]; then
# 		# Changement du fond d'écran de base qui revient souvent...
# 		if ! exec4user "cat ~/.config/plasma-org.kde.plasma.desktop-appletsrc" | grep "\[org.kde.image\]\[General\]"; then
# 			i=0;
# 			j=0;
# 			while read -r; do
# 				i=$((i+1));
# 				[[ $REPLY =~ Containments ]] && j=$((j+1)) && netw[$j]=$REPLY 
# 				[[ $REPLY =~ org.kde.desktopcontainment ]] && ctn=${netw[$j]} && j=$((i+2))
# 				[[ $j -eq $i ]] && echo "
# $ctn[Wallpaper][org.kde.image][General]
# FillMode=2
# Image=file:///media/srv/BACKUP/.dux/Images/Hogtied/037_3.jpg
# " >> /tmp/plasma-org.kde.plasma.desktop-appletsrc
# 				echo $REPLY >> /tmp/plasma-org.kde.plasma.desktop-appletsrc
# 				echo "$REPLY"
# 			done < <(exec4user "cat ~/.config/plasma-org.kde.plasma.desktop-appletsrc")
# 			exec4user "cp /tmp/plasma-org.kde.plasma.desktop-appletsrc ~/.config/plasma-org.kde.plasma.desktop-appletsrc"
# 		fi
# fi

exit 0
