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

### in cron job , the path may be just /bin and /usr/bin
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
#
gitHome="$(awk -F: -v v="git" '{if ($1==v) print $6}' /etc/passwd)"
gitlabHome="$gitHome/gitlab"
gitRakeBackups="$gitlabHome/tmp/backups"
PDIR=$(dirname $(readlink -f $0))
confFile="$PDIR/auto-gitlab-backup.conf"

###
## Functions
#

rvm_ENV() {
## environment for rvm
#
# rvm env --path -- ruby-version[@gemset-name]
if [[ "$RVM_envPath" != "" ]]
then
  echo "Using RVM environemnt file:"
  echo $RVM_envPath
  source $RVM_envPath
fi

}

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
    bundle exec rake gitlab:backup:create RAILS_ENV=production
}

rsyncUp() {
# rsync up with default key
    echo =============================================================
    echo -e "Start rsync to \n$remoteServer:$remoteDest\ndefault key\n"
    rsync -Cavz --delete-after -e "ssh -p$remotePort" $gitRakeBackups/ $remoteUser@$remoteServer:$remoteDest
}

rsyncKey() {
# rsync up with specific key
    echo =============================================================
    echo -e "Start rsync to \n$remoteServer:$remoteDest\nwith specific key\n"
    rsync -Cavz --delete-after -e "ssh -i $sshKeyPath -p$remotePort" $gitRakeBackups/ $remoteUser@$remoteServer:$remoteDest
}

rsyncDaemon() {
# rsync up with specific key
    echo =============================================================
    echo -e "Start rsync to \n$remoteUser@$remoteServer:$remoteModule\nin daemon mode\n"
    rsync -Cavz --port=$remotePort --password-file=$rsync_password_file --delete-after /$gitRakeBackups/ $remoteUser@$remoteServer::$remoteModule

}

sshQuotaKey() {
#quota check: with a key remoteServer, run the quota command
	if [[ $checkQuota == "true" || $checkQuota = 1 ]]
	then
	    echo =============================================================
	    echo -e "Quota check: \n$remoteUser@$remoteServer:$remoteModule\nwith key\n"
		ssh -p $remotePort -i $sshKeyPath $remoteUser@$remoteServer "quota"
	    echo =============================================================

	fi
}

sshQuota() {
#quota check: assuming we can ssh into remoteServer, run the quota command
	if [[ $checkQuota == "true" || $checkQuota = 1 ]]
	then
	    echo =============================================================
	    echo -e "Quota check: \n$remoteUser@$remoteServer:$remoteModule\n"
		ssh -p $remotePort $remoteUser@$remoteServer "quota"
	    echo =============================================================

	fi
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
        rvm_ENV
else
	echo "No confFile found; Remote copy DISABLED."
fi

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
		sshQuotaKey
		else if [[ $remoteServer != "" ]]
		then
			# use the defualt 
			rsyncUp
			sshQuota
		fi
	fi
fi

# Print version
printScriptver

###
## Exit gracefully
#
exit 0
