#!/bin/bash 
 
# BEGIN For locale_gen from ArchLinux /bin/locale-gen
is_entry_ok() {
	if [ -n "$locale" -a -n "$charset" ] ; then
		true
	else
		echo "error: Bad entry '$locale $charset'"
		false
	fi
}

locale_gen() {
	[[ -z "$1" ]] && die "Aucun répertoire défini !" 
	set -e

	LOCALEGEN="$1/etc/locale.gen"
	LOCALES="$1/usr/share/i18n/locales"
	if [ -n "$POSIXLY_CORRECT" ]; then
		unset POSIXLY_CORRECT
	fi

	[ -f $LOCALEGEN -a -s $LOCALEGEN ] || exit 0;

	# Remove all old locale dir and locale-archive before generating new
	# locale data.
	rm -rf $1/usr/lib/locale/* || true

	umask 022


	echo "Generating locales..."
	while read locale charset; do \
		case $locale in \#*) continue;; "") continue;; 
		esac; \
		is_entry_ok || continue
		echo -n "  `echo $locale | sed 's/\([^.\@]*\).*/\1/'`"; \
		echo -n ".$charset"; \
		echo -n `echo $locale | sed 's/\([^\@]*\)\(\@.*\)*/\2/'`; \
		echo -n '...'; \
		if [ -f $LOCALES/$locale ]; then input=$locale; else \
		input=`echo $locale | sed 's/\([^.]*\)[^@]*\(.*\)/\1\2/'`; fi; \
		arch_chroot "$1" "localedef -i $input -c -f $charset -A /usr/share/locale/locale.alias $locale;" 
		echo ' done'; \
	done < $LOCALEGEN
	echo "Generation complete."

}
# END

# See chroot_common.sh
chroot_setup() {
	CHROOT_ACTIVE_MOUNTS=()
#	TMP_ROOT=Arch Boostrap
	TMP_ROOT=$1
#	NEW_ROOT=$RACINE
	NEW_ROOT=$2
	
	[[ "${NEW_ROOT:${#NEW_ROOT}-1}" == "/"  ]] && NEW_ROOT="${NEW_ROOT:0:${#NEW_ROOT}-1}"
	mount_setup "$@"
	# WTF ???
# 	[[ "$CACHE_PAQUET" != ""  ]] && chroot_add_mount "$CACHE_PAQUET" "$1$DEFAULT_CACHE_PKG" -t none -o bind || return 0
	[[ "$CACHE_PAQUET" != ""  ]] && chroot_add_mount "$CACHE_PAQUET" "$1$DEFAULT_CACHE_PKG" -t none -o bind
	chroot_maybe_add_mount "! mountpoint -q '$TMP_ROOT$ROOT_DIR_BOOTSTRAP'" "$NEW_ROOT" "$TMP_ROOT$ROOT_DIR_BOOTSTRAP" -t none -o bind &&
	chroot_setup_others
	[[ -e $NAME_SCRIPT2CALL ]] && [[ ! -e "$1$WORK_DIR" ]] && mkdir -p $1$WORK_DIR 
	[[ -e $NAME_SCRIPT2CALL ]] && cp -R {$NAME_SCRIPT2CALL,files} $1$WORK_DIR/ 
}

recup_files () {
	local TMP=""
	for i in $( cat $1 | grep -v "#" ); do TMP+="$i "; done
	echo $TMP
}

desktop_environnement () {
	DE=$1
	SYSTD="$( recup_files files/systemd.conf )"
	# TODO Verifier si [[ -e files/de/$DE.conf  ]] est utile...
	LIST_SOFT="$( [[ -e files/de/$DE.conf  ]] && recup_files files/de/$DE.conf && printf " " && recup_files files/de/common.conf )"
	LIST_YAOURT="$( recup_files files/de/yaourt.conf )"
# 	bash
	echo $SYSTD > $TMPROOT$WORK_DIR/files/systemd.conf
	echo $LIST_SOFT > $TMPROOT$WORK_DIR/files/de/common.conf
	echo $LIST_YAOURT > $TMPROOT$WORK_DIR/files/de/yaourt.conf
}

# BEGIN fstab & load_langage
# bind mounts do not have a UUID! ( genfstab... )
set_uuid_fstab() {
	str="/"
	replace="\/"
	findmnt -Recvruno SOURCE,TARGET "$1" |
	while read -r src target fstype; do
		blkid | grep $src |
		while read -r disk ; do
			UUID="$( echo "$disk" | sed "s/.* UUID=\"/UUID=/" | sed "s/\".*//" )"
			exe sed -i "s/${src//$str/$replace}.*\//$UUID\t\//" $1/etc/fstab
		done
		# handle swaps devices
		{
		# ignore header
			read

			while read -r device type _ _ prio; do				
				UUID="$( blkid | grep "$device" | sed "s/.* UUID=\"/UUID=/" | sed "s/\".*//" )"
				exe sed -i "s/${device//$str/$replace}.*none/$UUID\tnone/" $1/etc/fstab
			done
		} </proc/swaps
	done
}

load_language() {
	local file_2_load

	LA_LOCALE="$1"
	[[ "${LA_LOCALE:${#LA_LOCALE}-5}" != "UTF-8"  ]] && LA_LOCALE+=".UTF-8" 
	
	file_2_load="files/lang/${LA_LOCALE:0:${#LA_LOCALE}-6}.trans"
	if [[ -e $file_2_load  ]]; then 
		source "$file_2_load" 
		return 0
	else
		file_2_load="files/lang/${LANG:0:${#LANG}-6}.trans"
		if  [[ -e $file_2_load  ]]; then 
			source $file_2_load 
			locale_2_load=${LANG:0:${#LANG}-6}
		else
			source "files/lang/en_GB.trans" 
			locale_2_load="en_GB"
		fi
		(( $( echo "$LA_LOCALE" | grep "_" | wc -l ) )) && msg_n2 "31" "31" "$_no_translation" "${LA_LOCALE:0:${#LA_LOCALE}-6}" "$locale_2_load" && return 0 
		LA_LOCALE="" && return 1 
	fi
}

anarchi_gpg_init() {
	msg_n "32" "Initialisation des cles GPG avec \"pacman-key --init\""
	caution "Cette opération peut prendre un certain temps !"
	# msg_n "Il est recommandé de lancer \"ls -R /\" pour aller plus vite."
	loading arch_chroot "$TMPROOT" "pacman-key --init" &
	PID_CHT=$!
# 	PID2KLL+=" $PID_CHT"
	ls -R / >/dev/null 2>&1 &
	PID_LS=$!
disown
	wait $PID_CHT
	kill $PID_LS >/dev/null 2>&1
	loading arch_chroot "$TMPROOT" "pacman-key --populate" 
	pkill gpg-agent

}
# END


# BEGIN main
source "$FILE2SOURCE$3-$4.conf"
source files/src/chroot_common.sh
# Used by run_once
work_dir=/tmp
# Bootstrap path
TMPROOT="$1"
# Real path
OLDROOT="$2"
# On repasse NO_EXEC a zero pour ecrire les commandes...
TMP_NO_EXEC=$NO_EXEC
NO_EXEC=0
FILE_COMMANDS=/tmp/anarchi_command
touch /tmp/anarchi_command

echo -e "#\n#\n# Anarchi (From non based Arch ) ($(date "+%Y/%m/%d-%H:%M:%S"))\n#\n#\n" >> $FILE_COMMANDS

declare -A to_mount

is_root "$@" 

chroot_setup "$TMPROOT" "$OLDROOT"  || die "$_failed_prepare_chroot" "$TMPROOT"
set_lang_chroot "$TMPROOT" 1 >> /dev/null &

echo "nameserver $( routel | grep default.*[0..9] | awk '{print $2}' )" >> $TMPROOT/etc/resolv.conf

sleep 1
run_once anarchi_gpg_init
cp files/pacman.conf.$ARCH $OLDROOT/pacman.conf.$ARCH
mkdir -m 0755 -p $OLDROOT$DEFAULT_CACHE_PKG
[[ -e $FILE2SOURCE*.conf ]] && cp $FILE2SOURCE*.conf $TMPROOT/tmp/

ls /tmp/ | grep -q done.anarchi* && cp /tmp/done.anarchi* $TMPROOT/tmp/

desktop_environnement "$5"

# On copie les fichier dans le 
[[ "$WIFI_NETWORK" != "" ]] && conf_net_wifi "$WIFI_NETWORK" && cp /tmp/$NET_CON files/
arch_chroot "$OLDROOT" "/bin/bash"
arch_chroot "$TMPROOT" "$COMMAND4ARCH"
PID_COM=$?

ls $TMPROOT/tmp | grep -q done.anarchi* && cp $TMPROOT/tmp/done.anarchi* /tmp/

[[ -e $TMPROOT/tmp/anarchi_command ]] && cat $TMPROOT/tmp/anarchi_command >> /tmp/anarchi_command
if [[ $PID_COM -eq 0 ]]; then
	NO_EXEC=$TMP_NO_EXEC
	set_uuid_fstab "$RACINE"
	final_message="$( set_lang_chroot "$RACINE" )\n"

	[[ "$NETERFACE" != "nfsroot"  ]] && [[ "$GRUB_INSTALL" == ""  ]] && bash files/extras/genGrub.sh "$RACINE" "$NAME_MACHINE" > /tmp/grub_$NAME_MACHINE && msg_n "32" "32" "$_grub_created" "\"/tmp/grub_$NAME_MACHINE\""
fi
NO_EXEC=0
pkill gpg-agent >> /dev/null 2>&1

clear_line
chroot_teardown "reset"

FIN=$PID_COM
NO_EXEC=$TMP_NO_EXEC
echo -e "#\n#\n# Anarchi Ending ($(date "+%Y/%m/%d-%H:%M:%S"))\n#\n#\n" >> $FILE_COMMANDS

# END
