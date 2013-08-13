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
    echo "and take care of anything else needed to restore"
    echo ""
    echo "USAGE:"
    echo "${0} -r [backup file]"
    echo "with only -r, I'll look for your gitlab install in the normal place"
    echo "(/home/git/gitlab) or you an specify the full path to the backup"
    
    exit 0
}

sanityCheck() {
	echo "git's home is determined to be : $gitHome"
	echo "gitlab backups are found in : $gitlabBackups"
}

getFileList() {
	echo "File list in : $1"
	e=1
	shopt -s nullglob
	for f in $1/*; do
	    [[ -e $f ]] && [[ -f $f ]] || continue
	    fileArray[$e]=$f
	    ((e++))
	done
	shopt -u nullglob
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
        chooseBackup
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
	## TODO add option to exit in array at this point
	select chosen in ${fileArray[@]};
do
	echo "you picked $chosen "
	break;
done


	
}

chooseBackupWhiped() {
	echo "Choose from below which backup to restore from:"
	
	# make sure we don't have an empty list
	WC=`echo ${fileArray[@]} | wc -l`
	
	if [[ "${WC}" -ne 0 ]]
	then
    	whiptail --backtitle "Welcome to SEUL" --title "Restore Files" \
    --menu "Please select the file to restore" 14 40 6 "${fileArray[@]}"
	fi

    # if [[ $? == 255 ]]
# 	then
# 	    do cancel stuff
# 	fi

	
}

rakeRestore() {
	cd $gitlabDir
# 	bundle exec rake gitlab:backup:restore RAILS_ENV=production
#	bundle exec rake gitlab:backup:restore RAILS_ENV=production BACKUP=timestamp_of_backup
	echo "rakeRestore"
 	echo "bundle exec rake gitlab:backup:restore RAILS_ENV=production BACKUP=$chosen"
}

rakeRestoreSingle() {
	cd $gitlabDir
# 	bundle exec rake gitlab:backup:restore RAILS_ENV=production
#	bundle exec rake gitlab:backup:restore RAILS_ENV=production BACKUP=timestamp_of_backup
	echo "rakeRestoreSingle"
 	echo "bundle exec rake gitlab:backup:restore RAILS_ENV=production"
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
        echo $i
		sudo -u git ln -sf $gitHome/gitlab-shell/hooks/post-receive $i/hooks/post-receive
    done
    

	echo "postRestoreLink"
}
# 
rakeInfo() {
	cd $gitlabDir
# 	bundle exec rake gitlab:env:info RAILS_ENV=production
	echo "rakeInfo"
}
# 
# 
rakeCheck() {
	cd $gitlabDir 	
# 	bundle exec rake gitlab:check RAILS_ENV=production
	echo "rakeCheck"
}


###
## Git'r done
#

case "$1" in
    "-r")
        # find the backup and make a list
		sanityCheck
        getFileList $gitlabBackups
        printFileList
        verifyRestore
        
        # fix things
        #permsFixBase
        postRestoreLink
        rakeCheck
        rakeInfo
    ;;
    
    "-R")
        # take entered path to backup and restore
        sanityCheck
        usage
    ;;

    "-t")
    	sanityCheck
        #getFileList $gitlabBackups
        #printFileList
        #verifyRestore
        
        # fix things
        #permsFixBase
        postRestoreLink
        #rakeCheck
        #rakeInfo
        
    ;;

    *)
        usage
    ;;
esac

###
## Exit gracefully
#
exit 0