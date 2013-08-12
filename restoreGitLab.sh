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
gitlabBackups=$gitHome/gitlab/tmp/backups/

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

getFileList() {
	e=1
	shopt -s nullglob
	for f in $1/*; do
	    [[ -e $f ]] && [[ -f $f ]] || continue
	    array[$e]=$f
	    ((e++))
	done
	shopt -u nullglob
}

printFileList() {
    echo "Files in $1"
    echo "Array is ${array[@]}"
    
    # print out each element with while based
    # on # of elements of array
    e=1
    while [ $e -le ${#array[@]} ]
    do
        echo "Element $e is : ${array[$e]}"
        ((e++))
    done
    
    #e=1
    #for c in ${array[@]};
    #do  
    #    echo "element $e is "
     #   echo $c
     #   ((e++))
     #   # print out file #
    #done
    echo ${array[0]}
}


# rakeRestore() {
# 	bundle exec rake gitlab:backup:restore RAILS_ENV=production
#	bundle exec rake gitlab:backup:restore RAILS_ENV=production BACKUP=timestamp_of_backup
# 	
# }
# 
# permsFixBase() {
	# Fix the permissions on the repository base
	sudo chmod -R ug+rwX,o-rwx /usr/local/home/git/repositories/
	sudo chmod -R ug-s /usr/local/home/git/repositories/
	sudo find /usr/local/home/git/repositories/ -type d -print0 | sudo xargs -0 chmod g+s
# 	
# }
# 
# postReceiveLink() {
# 	# find a list of repos put into array and loop through the array
# 	sudo -u git ln -sf /usr/local/home/git/gitlab-shell/hooks/post-receive /usr/local/home/git/repositories/libsys/scripts.git/hooks/post-receive
# }
# 
# rakeInfo() {
# 	
# 	bundle exec rake gitlab:env:info RAILS_ENV=production
# }
# 
# 
# rakeCheck() {
# 	
# 	bundle exec rake gitlab:check RAILS_ENV=production
# }


###
## Git'r done
#

case "$1" in
    "-r")
        # find the backup and make a list
        
    ;;
    
    "-R")
        # take entered path to backup and restore
        usage
    ;;

    "-t")
        getFileList $gitlabBackups
        printFileList
    ;;

    *)
        usage
    ;;
esac

###
## Exit gracefully
#
exit 0