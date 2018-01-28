#!/bin/bash
# This files should contains usefull fonctions

# Count the "1" in a IPv4 adress
# eg : $1=255.255.255.0 return 24
mask2bits() { local count=0; for nb in $(echo "$1" | sed "s/\./ /g"); do count=$((count+$(($(echo "obase=2;$nb" | bc | sed "s/0//g" | wc -m)-1)))); done; echo $count; }
# Return true if $1 match an ip adress
# Accept network adress endind with "0"
# eg: 192.168.1.0
isIPv4() { local zero="1"; [[ "$1" == "0" ]] && zero="0" && shift; if [[ $# = 1 ]]; then printf $1 | grep -Eq "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-4]|2[0-4][0-9]|[01]?[$zero-9][0-9]?)$"; return $?; else return 2; fi; }

# Return true if $2 is set and $1 > $2
# TODO A Verifier...
is_sup() { [[ ! -z $2 && $1 -gt $2 ]] && return 1; return 0; }
# 
# # Display a message then return user's entry if it's not empty
# # q to quit
# get_text() {
# 	local txt2return="" 
# # 	default="$2";
# 	while [[ "$txt2return" == "" ]]; do
# 		txt2return="$( rid "$@" )"
# # 		[[ "$txt2return" == "" ]] && [[ ! -z $default ]] && txt2return="$default"
# 		[[ "$txt2return" == "q" ]] && return 1
# 	done	
# 	echo "$txt2return"
# }

# # Display error message for 1 second
# choix2error() { msg_nn "\r" "31" "31" "$@" && sleep 1; }
# Return true if $1 is blocs device and display error message
is_blockdev() { local valid=0; [[ ! -b "$1" ]] && choix2error "\"%s\" n'est pas un peripherique de blocs !" "$1" && valid=1; return $valid; }
# Return true if $1 exists device and display error message
is_existpath() { local valid=0; [[ ! -e "$1" ]] && choix2error "\"%s\" n'existe pas !" "$1" && valid=1; return $valid; }
# 
str2ssl() { echo "$1" | openssl enc -base64; }
## Waits until a statement succeeds or a timeout occurs
# $1: timeout in seconds
# $2...: condition command
timeout_wait() {
    local timeout=$1
    (( timeout *= 5 ))
    shift
    until eval "$*"; do
        (( timeout-- > 0 )) || return 1
        sleep 0.2
    done
    return 0
}
# Helper function to run make_*() only one time it's finished with result 0.
run_once() {
	if (( $NO_EXEC )); then
		${1}
		return 0
	fi
	if [[ ! -e ${work_dir}/done/${1} ]]; then
		${1}
		RES_RUN=$?
		[[ ! -e ${work_dir}/done ]] && mkdir ${work_dir}/done
		[[ ! $RES_RUN -gt 0 ]] && touch ${work_dir}/done/${1}
		return $RES_RUN
	fi
	return 0
}
      
# # Va etre usefull !
# _maybe_doit() {
#   local cond=$1; shift
#   if eval "$cond"; then
#     "$@"
#   fi
# }

# exe echo "salut-\$(pwd)\" >> test"
# FILE_COMMANDS="/tmp/exe_commands"
# [[ ! -z $1 ]] && source_files "${@}"
