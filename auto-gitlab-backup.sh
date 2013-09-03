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

gitHome="$(awk -F: -v v="git" '{if ($1==v) print $6}' /etc/passwd)"
gitlabHome="$gitHome/gitlab"
gitRakeBackups="$gitlabHome/tmp/backups"
PDIR=$(dirname $(readlink -f $0))
confFile="$PDIR/auto-gitlab-backup.conf"

###
## environment for rvm
#

# rvm env --path -- ruby-version[@gemset-name]
source /usr/local/rvm/environments/ruby-1.9.3-p448

###
## Functions
#

checkSize() {
    echo ===== Sizing =====
    echo "Total disk space used for backup storage.."
    echo "Size - Location"
    echo `du -hs "$gitRakeBackups"`
    echo
}

rakeBackup() {
    echo ===== raking a backup =====
    cd $gitlabHome
    sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
}

rsyncUp() {
# rsync up with default key
    echo =============================================================
    echo -e "Start rsync to \n$remoteServer:$remoteDest\ndefault key"
    echo =============================================================
    rsync -Cavz --delete-after -e "ssh -p$remotePort" $gitRakeBackups/ $remoteUser@$remoteServer:$remoteDest
}

rsyncKey() {
# rsync up with specific key
    echo =============================================================
    echo -e "Start rsync to \n$remoteServer:$remoteDest\nwith specific key"
    echo =============================================================
    rsync -Cavz --delete-after -e "ssh -i $sshKeyPath -p$remotePort" $gitRakeBackups/ $remoteUser@$remoteServer:$remoteDest
}

rsyncDaemon() {
# rsync up with specific key
    echo =============================================================
    echo -e "Start rsync to \n$remoteServer:$remoteDest\nin daemon mode"
    echo =============================================================
    rsync -Cavz --port=$remotePort --password-file=$rsync_password_file --delete-after /$gitRakeBackups/ $remoteUser@$remoteServer::$remoteModule
}

printScriptver() {
	# print the most recent tag
	echo "This is $0"
	echo "Version $(git describe --abbrev=0 --tags), commit #$(git log --pretty=format:'%h' -n 1)."
}

###
## Git'r done
#

# read the conffile
if [ -e $confFile -a -r $confFile ]
then
	source $confFile
	echo "Parsing config file..."
else
	echo "No confFile found; Remote copy DISABLED."
fi

echo $PATH
echo $GEM_PATH

rakeBackup
checkSize

# go back to where we came from
cd $PDIR

# if the $remoteModule is set run rsyncDaemon
## here we assume variables are set right and only check when needed.
if [[ $remoteModule != "" ]]
then
	rsyncDaemon
	
# no Daemon so lets see if we are using a special key
else if [ -e $sshKeyPath -a -r $sshKeyPath ] && [[ $sshKeyPath != "" ]]
	then
	
		rsyncKey
	else if [[ $remoteServer != "" ]]
	then
		# use the defualt 
		rsyncUp
		fi
	fi
fi

# Print version
printScriptver

###
## Exit gracefully
#
exit 0
