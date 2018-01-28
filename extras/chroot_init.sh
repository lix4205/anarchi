#!/bin/bash


DIR_SCRIPTS="$( dirname "$0" )" 
[[ "$0" == "/usr/bin/chroot-extra" || "$0" == "/bin/chroot-extra" ]] && DIR_SCRIPTS="/usr/share/dists-extra/extras"

source $DIR_SCRIPTS/src/sources_files.sh chroot_common.sh info2show

# (( ! EUID == 0 )) && die "You have to log root !\n" && exit 1; 
[[ -z "$1" ]] && die "No directory specified !"
# On vérifie que ce n'est pas "/" puis qu'on est bien sur un système...
if [[ -e "$1" ]] && [[ "$1" != "/" ]]; then
	if [[ -e "$1/bin" ]] && [[ -e "$1/dev" ]] && [[ -e "$1/proc" ]] && [[ -e "$1/sys" ]] && [[ -e "$1/run" ]] && [[ -e "$1/tmp" ]]; then 
		[[ -d $1/bin ]] && PATH=$PATH:/bin:/sbin:/usr/sbin
		msg_info -n "Setup chroot to \"$1\"\r"
		init_chroot "$1" || die "Failed to setup chroot in /"
		msg_info "Setup chroot to \"$1\"...ok"
		msg_info "Chrooting to \"$1\""
		chroot "$1"
	else
		die "Unable to find a valid system in \"$1\"!"
	fi
else
	die "\"$1\" is not valid directory !"
fi
# echo "ok"
exit 0
