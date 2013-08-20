#!/bin/bash

################################
#
# autogitbackup.sh
# -----------------------------
#
# this script backups
# /home/git/repositories to
# another host
################################

## GPL v2 License
# auto-gitlab-backup
# Copyright (C) 2013  Shaun Sundquist
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

###
## Settings/Variables
#

gitHome=$(awk -F: -v v="git" '{if ($1==v) print $6}' /etc/passwd)
gitlabDir=$gitHome/gitlab
gitlabBackups=$gitlabDir/tmp/backups

###
## Functions
#

usage() {
    echo "${0} will restore a gitlab backup"
    echo "and (in most cases) take care of anything"
    echo "else needed to restore"
    echo ""
    echo "USAGE:"
    echo "${0} -R restore to a gitlab install in a place other than /home/git"
    echo ""
    echo "${0} -r restore to a gitlab install in /home/git"
    
    exit 0
}

sanityCheck() {
	echo "git's home is found to be : $gitHome"
	echo "gitlab backups are found in : $gitlabBackups"
}

getFileList() {
	#echo "File list in : $1"
	
	# best not to use ls to get a listing of a dir
	local e=1
	shopt -s nullglob
	for f in $1/*; do
	    [[ -e $f ]] && [[ -f $f ]] || continue
	    fileArray[$e]=$(basename "$f")
	    ((e++))
	done
	shopt -u nullglob
	
	#echo "fileArray is : ${fileArray[@]}"
	#echo "fileArray size is : ${#fileArray[@]}"
	
	## sort array so newest is first
	
	local c=1
	for ((i=${#fileArray[@]}; i>=1; i--)); do
		echo " sort i : $i & c $c"
		REVfileArray[$c]="${fileArray[$i]}"
		((c++))
	done
	
	#echo "REVfileArray is : ${REVfileArray[@]}"
	#echo "REVfileArray size is : ${#REVfileArray[@]}"
		
	## copy REVfileArray to fileArray
	unset fileArray
	
	for ((i=${#REVfileArray[@]}; i>=1; i--)); do
		fileArray[$i]="${REVfileArray[$i]}"
	done
	
	#echo "did we reasign? : ${fileArray[@]}"
	#echo "reset fileArray size is : ${#fileArray[@]}"
}

printFileList() {
    echo "Array is ${fileArray[@]}"
    
    # print out each element with while based
    # on # of elements of array
    e=1
    while [ $e -le ${#fileArray[@]} ]
    do
        echo "Element $e is : ${fileArray[$e]}"
        ((e++))
    done
    
    echo "Reversed is : ${REVfileArray[@]}"
    
	# print each elemt
	local z=0
    while [ $z -le ${#fileArray[@]} ]
    do
    	echo "Element $z of REVfileArray is : ${REVfileArray[$z]}"
		((z++))
	done


}

verifyRestore() {
	case "${#fileArray[@]}" in
    0)
        # if the file list is 0 then exit with message
        echo "ERROR: I didn't find any backup files in $gitlabBackups."
        echo "Copy or restore backups to $gitlabBackups."
        exit 1
    ;;
    
    1)
        # if the file list is 1 skip the menu and ask if ready to restore
        verifySingle
    ;;

    *)
    	# if the file list is grather than 1, menu time
    	## if whiptale installed, use
        if `command -v whiptail > /dev/null`
        then
        	chooseBackupWhiped
        else
        	chooseBackup
        fi
        rakeRestore

    ;;
esac

}

verifySingle() {
	echo "${fileArray[1]} was the only backup file found to restore from."
	
	
	if [ -f ${fileArray[1]} ]
	then
		read -p " Proceed with restore? (Y/n)" yesorno
    case $yesorno in
            y*) 
            	rakeRestoreSingle
				;;
            n*)
            echo "${fileArray[1]} has not been restored"
            exit 1
            ;;
    esac
fi
	
}

chooseBackup() {
	echo "Choose from below which backup to restore from:"
	echo "** The newest will be at the bottom of the list! **"
	## TO DO: add option to exit in array at this point
	## TO DO: invert array, newest on top
	
	fileArray=("${fileArray[@]}" "Abort")
	
	select chosen in ${fileArray[@]};
	do
		echo "you picked $chosen "
		break;
	done

	if [[ "$chosen" == "Abort" ]]
	then
		echo "Aborting backup!"
		exit 1
	fi
	
}

chooseBackupWhiped() {
	# make sure we don't have an empty list
	WC=`echo ${fileArray[@]} | wc -l`
	
	if [[ "${WC}" -ne 0 ]]
	then
		# create the whippedList
		i=0
		s=1    # decimal ASCII "A" 
		for f in ${fileArray[@]}
			do
				# convert to octal then ASCII character for selection tag
				whippedListArray[i]="$f"
				whippedListArray[i+1]=" "    # save file name
				((i+=2))
				((s++))
		done
		
		## calc screen height and width
		whipHeight=20 # find away to calc a pleasing height
		whipWidth=42 # find away to calc a pleasing height
		
		# whiptail uses stdin and stdout to draw boxes, have to reassign with 3>&1 1>&2 2>&3
    	chosen=$(whiptail --backtitle "Restore a GitLab Backup" --title "Restore from backup" \
			--menu "Please select the file to restore" "$whipHeight" "$whipWidth" \
			"${#fileArray[@]}" "${whippedListArray[@]}" 3>&1 1>&2 2>&3)
	fi

	#echo " you chose : $chosen"
	
}

rakeRestore() {
	cd $gitlabDir
	# if chosen is null then abort
	if [ -z "$chosen" ]
	then
		echo "Cancelling restore..."
		exit 1
	fi
	
	backupfilename=$(basename "$chosen")
	echo $backupfilename
	timeStamp=${backupfilename%_gitlab_backup.tar}
	echo "timestamp is : $timeStamp"
	# restore the chosen backup
 	sudo -u git -H bundle exec rake gitlab:backup:restore RAILS_ENV=production BACKUP=$timeStamp
 	echo " rake gitlab:backup:restore returned : $?"
}

rakeRestoreSingle() {
	cd $gitlabDir
	# restore the only backup available; will complain if it finds more than one
 	sudo -u git -H bundle exec rake gitlab:backup:restore RAILS_ENV=production
 	echo " rake gitlab:backup:restore returned : $?"
}

permsFixBase() {
	cd $gitlabDir
	# Fix the permissions on the repository base
	# repositories ahould be found in git's home
	sudo chmod -R ug+rwX,o-rwx $gitHome/repositories/
	sudo chmod -R ug-s $gitHome/repositories/
	sudo find $gitHome/repositories/ -type d -print0 | sudo xargs -0 chmod g+s
# 	
}

postRestoreLink() {
	cd $gitlabDir
	# 	# find a list of repos put into array
	
	local folderFound=("`sudo -u git -H find $gitHome/repositories -name *.git -type d -print`")
    declare -a gitfolderArray
    gitfolderArray=(${folderFound// / })
    
    echo "I found ${#gitfolderArray[*]} git repos."
    
    #and loop through the array
    
    for i in ${gitfolderArray[@]}; do
        echo "Creating symlink to $i/hooks/post-receive"
		sudo -u git ln -sf $gitHome/gitlab-shell/hooks/post-receive $i/hooks/post-receive
    done
}
# 
rakeInfo() {
	cd $gitlabDir
 	sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
}
# 
# 
rakeCheck() {
	cd $gitlabDir 	
 	sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
}

###
## Git'r done
#

case "$1" in
    "-R") ## gitlab in place other than /home/git
        # find the backup and make a list
		sanityCheck
        getFileList $gitlabBackups
        #printFileList
        verifyRestore
         #chooseBackupWhiped
        # fix things
        ## if the rake fails (it will with different git home
        # run the fixes
        ## TO DO determine if we really need to run these
        permsFixBase
        postRestoreLink
        rakeInfo
        rakeCheck
    ;;
    
    "-r") ## gitlab in /home/git
          # find the backup and make a list
          sanityCheck
          getFileList $gitlabBackups
          #printFileList
          verifyRestore
        # run the fixes
        ## TO DO determine if we really need to run these
         # permsFixBase
         # postRestoreLink
          rakeInfo
          rakeCheck
    ;;

    "-t")
    	sanityCheck
        getFileList $gitlabBackups
        #printFileList
        verifyRestore
        
        # fix things
        permsFixBase
        postRestoreLink
        rakeInfo
        rakeCheck
        
    ;;

    *)
        usage
    ;;
esac

###
## Exit gracefully
#
exit 0
