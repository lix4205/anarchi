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

#
# Another Arch Installer
#
#
# Assumptions:
#  1) User has partitioned, formatted, and mounted partitions on /mnt
#  2) Network is functional
#  3) Arguments passed to the script are valid pacman targets
#  4) A valid mirror appears in /etc/pacman.d/mir1rorlist
#

usage() {
  cat <<EOF
usage: ${0##*/} [options] root [packages...]

  Options:
    -C config      Use an alternate config file for pacman
    -d             Allow installation to a non-mountpoint directory
    -G             Avoid copying the host's pacman keyring to the target
    -i             Avoid auto-confirmation of package selections
    -M             Avoid copying the host's mirrorlist to the target
    -a architecture                       Architecture du processeur (x64/i686)
    -g graphic driver to install          Pilote carte graphique (intel,nvidia{-304,340},radeon)
    -e desktop environnement              Environnement de bureau (plasma,xfce,lxde,gnome,mate,fluxbox,cinnamon)
    -h hostname                           Nom de la machine
    -u username                           Login utilisateur
    -n [ nm, dhcpcd@<< network_interface >> ]       Utilisation de NetworkManager ou dhcpcd (avec l'interface NETWORK_INTERFACE)
    -l /dev/sdX                           Installation de grub sur le péripherique /dev/sdX.
    -c CACHE_PAQUET           		Utilisation des paquets contenu dans le dossier CACHE_PAQUET

    -h             Print this help message

pacinstall installs packages named in files/de/*.conf to the specified new root directory.
Then generate fstab, add the user,create passwords, install grub if specified,
enable systemd services like the display manager
And files/custom.d/<username> is executed as a personal script 

EOF
}
    
# See chroot_common.sh
chroot_setup() {
	init_chroot "$RACINE"
	[[ -e $NAME_SCRIPT ]] && [[ ! -e "$1$PATH_WORK" ]] && mkdir -p $1$PATH_WORK 
	[[ -e $NAME_SCRIPT ]] && cp -R files $1$PATH_WORK/

# 	[[ "$CACHE_PAQUET" != "" ]] && chroot_add_mount "$CACHE_PAQUET" "$1$DEFAULT_CACHE_PKG" -t none -o bind || return 0
}

set_sudo() {
	show_msg msg_n "32" "32" "$_init_sudo" "sudo"
	exe ">" $RACINE/etc/sudoers.d/$1 echo "$1 $sudo_entry" 
# 	arch_chroot "gpasswd -a $1 sudo" 
	arch_chroot "passwd -l root" 
}

set_pass_chroot () {
	if [[ ! -z "$2" ]]; then
		(( ! $NO_EXEC )) && lix_chroot $RACINE "echo "$1:$2" | chpasswd"

		# In log...
		echo "chroot passwd $1" >> $FILE_COMMANDS
	else
		show_msg msg_n2 "31" "$_empty_pass" "$1"
	fi
}

# BEGIN CONFIGURATION FONCTIONS
conf_net () {
	NETERFACE=$1
	[[ "$NETERFACE" == "nfsroot" ]] && CONF_NET="mkinitcpio-nfs-utils" || CONF_NET=""
	[[ $WIFI_NETWORK =~ "wpa" || $WIFI_NETWORK =~ "netctl" ]] && CONF_NET="wpa_supplicant" 
}

graphic_setting () {
	if (( ! FROM_FILE )); then
		DRV_VID=$1
		if [[ ! -z "$DRV_VID" ]] && [[ ${graphic_drv[$DRV_VID]} ]]; then
			DRV_VID=${graphic_drv[_$DRV_VID]}
		else
			ERROR="\n\t\"-g GRAPHIC_DRIVER\" Invalid option : Graphics settings incorrect !"
		fi
	else
		DRV_VID=
	fi
}

recup_files () {
 	local TMP=""
	if (( ! EXEC_DIRECT )); then
		for i in $( cat $1 | grep -v "#" ); do TMP+="$i "; done
		echo $TMP
	else
		echo -ne $( tail -n 1 $1 )
	fi

}

desktop_environnement () {
	DE=$1
	[[ -z "$GRUB_INSTALL" ]] && GRUB_PACKAGES=""
	[[ "$DRV_VID" != "0" ]] && ADD_PACKAGES=""
	SOFTLIST="$BASE_PACKAGES $GRUB_PACKAGES $ADD_PACKAGES"
	SYSTD="$( recup_files files/systemd.conf )"
# NOTE Voir aussi desktop_environnement() dans linux-part.sh
	LIST_SOFT="$SYNAPTICS_DRIVER $CONF_NET $( (( ! EXEC_DIRECT )) && [[ -e files/de/$DE.conf ]] && recup_files files/de/$DE.conf && printf " "; recup_files files/de/common.conf )"
# 	(( ! FROM_FILE )) && LIST_SOFT="$LIST_SOFT"
	LIST_YAOURT="$( recup_files files/de/yaourt.conf )"
}

get_pass () {
	USR=$1
	local color="$2"
	count=2
	pass_user_tmp=$( rid_pass "33" "$color" "$_pass_user1" "$USR"  )
	while [[ "$( rid_pass  "33" "$color" "$_pass_user2"  )" != "$pass_user_tmp" ]]; do
		if [[ $count == 2 ]]; then
			error "$_error_pass" >&2
			count=1
		fi
		pass_user_tmp=$( rid_pass  "33" "$color" "$_pass_user1" "$USR" )
		count=$((count+1))
	done
	echo "$pass_user_tmp"
}

load_language() {
	local file_2_load

	LA_LOCALE="$1"
	[[ "${LA_LOCALE:${#LA_LOCALE}-5}" != "UTF-8" ]] && LA_LOCALE+=".UTF-8" 
	
	file_2_load="files/lang/${LA_LOCALE:0:${#LA_LOCALE}-6}.trans"
	if [[ -e $file_2_load ]]; then 
		source "$file_2_load" 
		return 0
	else
		file_2_load="files/lang/${LANG:0:${#LANG}-6}.trans"
		if  [[ -e $file_2_load ]]; then 
			source $file_2_load 
			locale_2_load=${LANG:0:${#LANG}-6}
		else
			source "files/lang/en_GB.trans" 
			locale_2_load="en_GB"
		fi
		(( EXEC_DIRECT )) && [[ "${1:${#1}-5}" != "UTF-8" ]] && msg_n2 "31" "31" "$_no_translation" "${LA_LOCALE:0:${#LA_LOCALE}-6}" "$locale_2_load" && return 0
		(( $( echo "$LA_LOCALE" | grep "_" | wc -l ) )) && msg_n2 "31" "31" "$_no_translation" "${LA_LOCALE:0:${#LA_LOCALE}-6}" "$locale_2_load" && return 0 
		LA_LOCALE="" && return 1 
	fi
}

anarchi_create_root() {
	show_msg msg_n "33" "32" "$_creating_root" "$RACINE"
	exe mkdir -m 0755 -p "$RACINE"/var/{cache/pacman/pkg,lib/pacman,log} "$RACINE"/{dev,run,etc}
	exe mkdir -m 1777 -p "$RACINE"/tmp 
	exe mkdir -m 0555 -p "$RACINE"/{sys,proc} 
}
# Install base system
anarchi_base() {
	show_msg msg_n "33" "32" "$_pacman_install" "$RACINE"
	if ! exe $QUIET pacman -r "$RACINE" --config=$( [[ ! -z "$pacman_config" ]] && echo $pacman_config || echo $PATH_SOFTS/pacman.conf.$ARCH ) -Sy ; then
		die "$_pacman_fail" "$RACINE"
	fi

	if ! exe $QUIET pacman -r "$RACINE" -S --needed ${pacman_args[@]}; then
		die "$_pacman_fail" "$RACINE"
	fi
	if (( copykeyring )); then
	# if there's a keyring on the host, copy it into the new root, unless it exists already
		if [[ -d /etc/pacman.d/gnupg && ! -d $RACINE/etc/pacman.d/gnupg ]]; then
			exe cp -a /etc/pacman.d/gnupg "$RACINE/etc/pacman.d/"
		fi
	fi

	if (( copymirrorlist )); then
	# install the host's mirrorlist onto the new root
		exe cp -a /etc/pacman.d/mirrorlist "$RACINE/etc/pacman.d/"
	fi
	show_msg msg_n "32" "$_mi_install"
}
set_lang_chroot () {
	arch_chroot "$1" "sed -i s/\#$LA_LOCALE/$LA_LOCALE/g /etc/locale.gen"
	$exe ">" $1/etc/vconsole.conf echo "KEYMAP=\"$CONSOLEKEYMAP\"" 
	$exe ">" $1/etc/locale.conf echo "LANG=\"$LA_LOCALE\"" 
	arch_chroot "$1" "locale-gen"
# 	On force le TIMEZONE
	arch_chroot "$1" "ln -fs /usr/share/zoneinfo/$TIMEZONE /etc/localtime"
}


anarchi_conf() {
# echo $NAME_MACHINE > $RACINE/etc/hostname
	exe ">" $RACINE/etc/hostname echo $NAME_MACHINE 
	hosts_entry="${hosts_entry//%s/$NAME_MACHINE}"
# 	exe echo -e "$hosts_entry" > $RACINE/etc/hosts
	exe ">" $RACINE/etc/hosts echo -e "$hosts_entry" 
# echo -e "$hosts_entry" > $RACINE/etc/hosts
	
	[[ "${RACINE:${#RACINE}-1}" == "/" ]] && RACINE="${RACINE:0:${#RACINE}-1}"
	if [[ "$NETERFACE" != "nfsroot" ]]; then
# genfstab -U $RACINE >> $RACINE/etc/fstab
		exe ">>" $RACINE/etc/fstab genfstab -U $RACINE 
	fi
	set_lang_chroot "$RACINE"
	return 0
}

anarchi_custom() {
	if (( ! interactive )); then
        arch_chroot "bash /tmp/files/custom" 
    else
        msg "$_chroot_newroot_msg" "$NAME_MACHINE"
        arch_chroot "$RACINE" "/bin/bash"
    fi
}

anarchi_passwd() {
	show_msg msg_n2 "33" "32" "$_pass_msg" "$USER_NAME" 
	if arch_chroot "useradd -m -g users -G wheel -s /bin/bash $USER_NAME"; then
        [[ "$pass_root" == "sudo" ]] && set_sudo "$USER_NAME" || set_pass_chroot "root" "$pass_root" 
        set_pass_chroot "$USER_NAME" "$pass_user" 
    else
        show_msg caution "$_pass_unchanged" "$USER_NAME"
    fi
}

anarchi_pacman_conf() {
	# Write AUR config in pacman.conf
	[[ "$ARCH" == "x64" ]] && exe ">>" $RACINE/etc/pacman.conf echo -e "$pacman_multilib" 
# 	[[ "$ARCH" == "x64" ]] && exe echo -e "$pacman_multilib" >> $RACINE/etc/pacman.conf
	exe ">>" $RACINE/etc/pacman.conf echo -e "$pacman_yaourt" 
# 	exe echo -e "$pacman_yaourt" >> $RACINE/etc/pacman.conf
    return 0
}

anarchi_packages() {
	show_msg msg "$_yaourt_install" "$yaourt_args"
	show_msg decompte 9 "$_mi_install2" "$_go_on %s"

# 	Install others packages 
	if (( ! EXEC_DIRECT )); then
		sed -i "s/^[[:space:]]*SigLevel[[:space:]]*=.*$/SigLevel = Never/" "$PATH_SOFTS/pacman.conf.$ARCH"
		# Si pacman a flingué notre liste de mirroirs alors on la rafrachie !
		[[ -e $RACINE/etc/pacman.d/mirrorlist.pacorig ]] && sed -i "s/^#Server/Server/g" $RACINE/etc/pacman.d/mirrorlist
	fi
	
#	Install packages 
	! exe $QUIET pacman -r "$RACINE" -Sy --needed ${yaourt_args[@]} && die "$_pacman_fail" "$RACINE"

# 	[[ -e /tmp/00-keyboard.conf ]] && exe mkdir -p $RACINE/etc/X11/xorg.conf.d/ && exe cp /tmp/00-keyboard.conf $RACINE/etc/X11/xorg.conf.d/00-keyboard.conf 
	[[ -e /tmp/00-keyboard.conf ]] && exe cp /tmp/00-keyboard.conf $RACINE/etc/X11/xorg.conf.d/00-keyboard.conf 

}

anarchi_nfsroot() {
    show_msg msg_n2 "$_recompile_nfs" 
    arch_chroot "bash /tmp/files/nfs_root.sh"
}
anarchi_wifi() {
#	 Creation des connexions WiFi avec wifi-netctl
	TYPE_CON=${WIFI_NETWORK//@*/}
	NET_CON=${WIFI_NETWORK//*@/}
	NAME_CON=${WIFI_NETWORK//$TYPE_CON@/} 
	NAME_CON=${NAME_CON//@$NET_CON/}

	source /tmp/$NET_CON
	show_msg msg_n "Creation de la connexion au point d'acces \"%s\" avec \"%s\"." "$NET_CON" "$TYPE_CON"	
	cp -a $PATH_SOFTS $RACINE/tmp/
	cp /tmp/$NET_CON $RACINE/tmp/
	arch_chroot "bash /tmp/files/extras/wifi-utils.sh $NET_CON $TYPE_CON $NAME_CON /"
	[[ "$TYPE_CON" == "netctl" ]] && arch_chroot "netctl enable $NAME_CON"
	return 1

}

anarchi_systd() {
#	Activation des services systemd
	show_msg msg_n2 "32" "32" "systemctl enable %s" "$SYSTD"
	if ! arch_chroot "systemctl enable $SYSTD"; then
		die "$_systd_error" "$SYSTD"
	fi
}

anarchi_custom_user() {
	show_msg msg_n2 "32" "$_exec_custom"
	arch_chroot "bash /tmp/files/custom user"
}
anarchi_grub() {
	if (( ! $NO_EXEC )) && [[ ! -e $RACINE/usr/bin/grub-mkconfig ]]; then
		show_msg caution "$_grub_notinstalled"
		return 1
	fi
	show_msg msg_n "Installation de grub sur le disque \"%s\"" "$GRUB_INSTALL"
# 	echo -e "$grub_entries" >> "$RACINE/etc/grub.d/40_custom"
	exe ">>" "$RACINE/etc/grub.d/40_custom" echo -e "$grub_entries" 
	arch_chroot "grub-install --recheck $GRUB_INSTALL"
	arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
}
# END CONFIGURATION FONCTIONS

# Used by run_once
work_dir=/tmp


ERROR=
hostcache=0
copykeyring=1
copymirrorlist=1

ARCH=
GRUB_INSTALL=
SYSTD=
SYNAPTICS_DRIVER=
TIMEZONE="Europe/Paris"
CONSOLEKEYMAP="fr"
LA_LOCALE="fr_FR.UTF-8"
SOFTLIST=""
PATH_WORK="$work_dir/install"
PATH_INSTALL="/install.arch$PATH_WORK"
PATH_SOFTS="$PATH_INSTALL/files"
CONF2SOURCE="$work_dir/anarchi-"
DEFAULT_CACHE_PKG="/var/cache/pacman/pkg"
NAME_SCRIPT="pacinstall.sh"
FILES2SOURCE="files/src/doexec files/src/chroot_common.sh files/src/futil files/src/bash-utils.sh files/drv_vid"
FILE_COMMANDS=/tmp/anarchi_command
LOG_EXE="/tmp/anarchi.log"

pacman_multilib="\n#Multilib configuration\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" 
pacman_yaourt="\n#AUR configuration\n[archlinuxfr]\nServer = http://repo.archlinux.fr/\$arch\nSigLevel = Never" 
# Entries shutdown/restart GRUB
grub_entries="\n\nmenuentry \"System shutdown\" {\n\techo \"System shutting down...\"\n\thalt\n}"
grub_entries+="\n\nmenuentry \"System restart\" {\n\techo \"System rebooting...\"\n\treboot\n}"
sudo_entry="      ALL=(ALL) ALL"
# from ARCHitect + header
hosts_entry="#\n#\n# /etc/hosts: static lookup table for host names\n#\n#<ip-address>\t<hostname.domain.org>\t<hostname>\n127.0.0.1\tlocalhost.localdomain\tlocalhost\t%s\n::1\tlocalhost.localdomain\tlocalhost\t%s"
keyboard_conf="Section \"InputClass\"\n\tIdentifier \"system-keyboard\"\n\tMatchIsKeyboard \"on\"\n\tOption \"XkbLayout\" \"%s\"\nEndSection"
interactive_modes=("Installer les paquets de base" "Installer les paquets complémentaires" "Effectuer les opérations post installations (1) ( LANG, fstab, hostname, users/pass )" "Activer les services" "Installer grub sur le disque %s" "Executer les scripts de personnalisation" "Garder la main sur pacman" )


# Install Packages 
PACK_P=1
# Install Base packages only
BASE_P=1
# Install "Graphic" packages only
GRAP_P=1
# Generate fstab, hostname , hosts, user pass, 
LANG_P=1
# Systemd service, grub and customization
POST_P=1
# Grub
GRUB_P=1
# Services
SERV_P=1
# customization
CUST_P=1
FREE_PACMAN=1

# -x option initialise EXEC_DIRECT to 1 if we install ArchLinux from another distribution
# Arch Linux bootstrap image doesn't have sed or grep installed so we use them at the end of linux_parts.sh....
# EXEC_DIRECT=0
[[ "$1" == "-x" ]] && cd $PATH_WORK && EXEC_DIRECT=1 && shift

# Usefull functions
source files/src/sources_files.sh $FILES2SOURCE

echo -e "#\n#\n# Anarchi ($(date "+%Y/%m/%d-%H:%M:%S"))\n#\n#\n" >> $FILE_COMMANDS

# Set localisation
load_language "$1" && LA_LOCALE="$1" && shift && [[ "${LA_LOCALE:${#LA_LOCALE}-5}" != "UTF-8" ]] && LA_LOCALE+=".UTF-8" 
if (( ! EXEC_DIRECT )); then
	PATH_SOFTS="$PATH_WORK/files"
fi

if [[ -z $1 || $1 = @(-h|--help) ]]; then
    usage
    exit $(( $# ? 0 : 1 ))
fi

while getopts ':C:c:tdxGiMSqu:l:a:e:n:g:h:z:k:K:D:' flag; do
    case $flag in
        C) pacman_config=$OPTARG ;;
        d) directory=1 ;;
        i) interactive=1 ;;
        G) copykeyring=0 ;;
        M) copymirrorlist=0 ;;
        n) CONF_NET="$OPTARG" ;;
        a) ARCH="$OPTARG" ;;
        g) DRV_VID="$OPTARG" ;;
        e) DE="$OPTARG";;
        D) DM="$OPTARG";;
        K) X11_KEYMAP="$OPTARG" ;;
        k) CONSOLEKEYMAP="$OPTARG" ;;
        z) TIMEZONE="$OPTARG" ;;
        h) NAME_MACHINE="$OPTARG" ;;
        q) QUIET="-q" ;;
        # USELESS
        S) pass_root="sudo" ;;
#         SYNAPTICS_DRIVER="xf86-input-libinput" 
# 			s) SYNAPTICS_DRIVER="xf86-input-synaptics" ;;
        u) USER_NAME="$OPTARG" ;;
# 			t) TEST=1; COLORED_PROMPT=0 ;;
        t) NO_EXEC=1 ;;
# 			x) EXEC_DIRECT=1 ;;
        c) 
            hostcache=1
            [[ -d "$OPTARG" ]] && CACHE_PAQUET=$OPTARG || die "$_not_a_dir" $OPTARG
        ;;
        l)
            GRUB_INSTALL="$OPTARG"
            ! [[ -b "$GRUB_INSTALL" ]] && ERROR+="\n\t\"-l DISK\" : invalid parameter $_grub_unable $GRUB_INSTALL"
        ;;
        :) die "$_argument_option" "${0##*/}" "$OPTARG" ;;
        ?) die "$_invalid_option" "${0##*/}" "$OPTARG" ;;
    esac
done
shift $(( OPTIND - 1 ))
(( $# )) || die "$_nodir"

RACINE=$1; shift
OTHER_PACKAGES="$@"
    
# 	[[ -z "$ARCH" ]] && ERROR+="\n\t\"-a ARCHITECTURE\" Missing option" 
# 	[[ ! -z "$ARCH" && ( "$ARCH" != "x64" && "$ARCH" != "i686" ) ]] && ERROR+="\n\t\"-a ARCHITECTURE\" Invalid parameter : $ARCH" 
[[ -z "$NAME_MACHINE" ]] && ERROR+="\n\t\"-h HOSTNAME\" Missing option" 
[[ -z "$USER_NAME" ]] && ERROR+="\n\t\"-u USERNAME\" Missing option"

if [[ -z "$DRV_VID" ]]; then
	ERROR+="\n\t\"-g VIDEO_DRIVER\" Missing option"
else
	if [[ "$DRV_VID" != "0" ]]; then
		if [[ -e /etc/X11/xorg.conf.d/00-keyboard.conf ]]; then
			cp /etc/X11/xorg.conf.d/00-keyboard.conf /tmp/
		else
# 			echo -e "${keyboard_conf//%s/${X11_KEYMAP}}" > /tmp/00-keyboard.conf
			exe ">" /tmp/00-keyboard.conf echo -e "${keyboard_conf//%s/${X11_KEYMAP}}"
		fi
		graphic_setting "$DRV_VID"
	fi
fi
[[ "$CONF_NET" != "0" ]] && conf_net "$CONF_NET"
desktop_environnement "$DE"
	
[[ ! -z "$ERROR" ]] && die "$_invalid_param :$ERROR"

pacman_args=("$SOFTLIST")
yaourt_args="yaourt $LIST_SOFT $OTHER_PACKAGES"

if (( hostcache )); then
  pacman_args+=(--cachedir="$CACHE_PAQUET")
  yaourt_args+=(--cachedir="$CACHE_PAQUET")
fi

if (( interactive )); then
# Install Packages 
PACK_P=1
# Install Base packages only
BASE_P=0
# Install "Graphic" packages only
GRAP_P=0
# Generate fstab, hostname , hosts, user pass, 
LANG_P=0
# Systemd service, grub and customization
POST_P=1
# Grub
GRUB_P=0
# Services
SERV_P=0
# customization
CUST_P=0
FREE_PACMAN=1
show_imodes="$(rid_menu -q "Indiquez les opérations à effectuer (%s)." "${interactive_modes[@]}")"; 
msg_nn "$show_imodes"
while [[ -z "$validmodes" ]]; do
	validmodes=$(rid "\t->");
	[[ "$validmodes" == "q" ]] && exit 2;
	for modes in ${validmodes}; do
		if is_number $modes; then
			case $modes in 
				1) BASE_P=1 ;; # BASE_PACKAGES
				2) GRAP_P=1 ;; # Graphic packages
				3) LANG_P=1 ;; # Post install
				4) SERV_P=1 ;; # services a activer
				5) GRUB_P=1 ;; # install grub
				6) CUST_P=1 ;; # Script perso
				7) FREE_PACMAN=0 ;; # Garder la main sur pacman...
				*) validmodes= ;;
		# 		7) 
		# 		8) 	
			esac
		else
			validmodes=
		fi
	done
done

fi
(( $FREE_PACMAN )) && pacman_args+=(--noconfirm) && yaourt_args+=(--noconfirm)

if [[ ! -z "$pacman_config" ]]; then
	pacman_args+=(--config="$pacman_config")
	yaourt_args+=(--config="$pacman_config")
else
	pacman_args+=(--config="$PATH_SOFTS/pacman.conf.$ARCH")
	yaourt_args+=(--config="$PATH_SOFTS/pacman.conf.$ARCH")
fi
if (( $LANG_P )) && ! ls /tmp/done/*_passwd >> /dev/null 2>&1; then
	msg_n "$_set_pass_msg"
	[[ -z $pass_root ]] && pass_root="$( get_pass "root" "31" )"
# 	rid_continue "Utiliser \"sudo\" ?" && pass_root="sudo" || pass_root="$( get_pass "root" "31" )"
	pass_user="$( get_pass "$USER_NAME" "32" )"
fi
# BEGIN PAVE D'INFO 

msg_n "32" "$_info_gen"  
cat <<EOF
	$( [[ ! -z "$GRUB_INSTALL" ]] && echo "	$_info_grub \"$GRUB_INSTALL\" " ) 
	"$RACINE" $_info_root" 
	$_info_arch                			$ARCH
	$_info_drv_vid         			$DRV_VID
	$_info_net      			$CONF_NET$NETERFACE
	$_info_de   			$DE
	$_info_hostname         			$NAME_MACHINE
	$_info_user           			$USER_NAME
	
EOF
msg_n "32" "$_info_base"
echo "$SOFTLIST"
msg_n "32" "$_info_complement"
echo "$LIST_SOFT $OTHER_PACKAGES"
msg_n "32" "$_info_systd"
echo "$SYSTD"
[[ ! -z "$LIST_YAOURT" ]] && ( msg_n "32" "$_info_yaourt" ; echo "$LIST_YAOURT" ; )

[[ ! -z "$CACHE_PAQUET" ]] && ( msg_n "32" "$_info_cache" "$CACHE_PAQUET" )
[[ -z "$pass_root" ]] && caution "$_empty_pass" "root"
[[ -z "$pass_user" ]] && caution "31" "32" "$_empty_pass" "$USER_NAME"
rid_exit "$_continue"
msg_n "32" "$_go_on"
# END PAVE

# BEGIN CHROOT SETUP, PACMAN INSTALL & CONFIGURATION
run_once anarchi_create_root

chroot_setup "$RACINE" || die "$_failed_prepare_chroot" "$RACINE" 
(( ! EXEC_DIRECT )) && exe ">>" $RACINE/etc/resolv.conf echo "nameserver $( routel | grep default.*[0..9] | awk '{print $2}' )" 
# (( ! EXEC_DIRECT )) && exe echo "nameserver $( routel | grep default.*[0..9] | awk '{print $2}' )" >> $RACINE/etc/resolv.conf
# (( ! EXEC_DIRECT )) && chroot_add_resolv_conf "$RACINE"

if (( $PACK_P )); then
	if (( $BASE_P )); then
		# Install base system
		run_once anarchi_base
	fi
fi

# On exporte les variables nécessaires à l'execution de custom pour les utiliser en chroot
export NAME_USER=$USER_NAME LIST_SOFT SYSTD_SOFT="$SYSTD" GRUB_DISK=$GRUB_INSTALL NFSROOT=$NETERFACE DE DM X11_KEYMAP ARCH LIST_YAOURT
# Et on copie les fichiers dans /tmp de la nouvelle install pour les executer en chroot		
exe cp -a "$PATH_SOFTS" $RACINE/tmp/

if (( $LANG_P )); then
	run_once anarchi_conf
	(( $CUST_P )) && run_once anarchi_custom
	run_once anarchi_passwd
fi
if (( $PACK_P )); then
	if (( $GRAP_P )); then	
		run_once anarchi_pacman_conf
		run_once anarchi_packages
	fi

fi
# END CHROOT SETUP, PACMAN INSTALL & CONFIGURATION

if (( $POST_P )); then
	show_msg msg_n "32" "32" "%s" "$_finalisation"
	if (( $SERV_P )); then
		if [[ ! -z "$WIFI_NETWORK" ]]; then
			run_once anarchi_wifi
		fi
		run_once anarchi_systd
	fi
# 	mount the host's resolv.conf in the fresh install 
	chroot_add_resolv_conf "$RACINE"	
	
	if (( $CUST_P )); then
		run_once anarchi_custom_user
	fi
	if [[ "$NETERFACE" == "nfsroot" ]]; then
#         Run NFS post installation configuration
        run_once anarchi_nfsroot
#         Generate a syslinux entry and display it at the end of installation
		final_message="$( bash files/extras/genloader.sh "$NAME_MACHINE" "$ARCH" "$DE" "$RACINE" )"
    else
# 	GRUB
        if (( $GRUB_P )) && [[ ! -z "$GRUB_INSTALL" ]]; then
            run_once anarchi_grub &&
            (( ! NO_EXEC )) && final_message="$_grub_installed $GRUB_INSTALL"
        fi
	fi
	# 	Generate a grub entry and display it at the end of installation
	if (( ! EXEC_DIRECT )) && [[ "$NETERFACE" != "nfsroot" ]] && [[ -z "$GRUB_INSTALL" ]]; then
        bash files/extras/genGrub.sh "$RACINE" "$NAME_MACHINE" > /tmp/grub_$NAME_MACHINE && 
        show_msg msg_n "32" "32" "$_grub_created" "\"/tmp/grub_$NAME_MACHINE\""
    fi
	cat <<EOF
$final_message

EOF
fi
echo -e "#\n#\n# Anarchi Ending ($(date "+%Y/%m/%d-%H:%M:%S"))\n#\n#\n" >> $FILE_COMMANDS
