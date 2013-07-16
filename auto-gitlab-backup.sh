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

###
## Settings/Variables
#

gitHome="/home/git"
gitlabHome="$gitHome/gitlab"
gitRakeBackups="$gitlabHome/tmp/backups"
PDIR=$(dirname $(readlink -f $0))
confFile="$PDIR/auto-gitlab-backup.conf"

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
    echo Start rsync to rsync.net/backup no key
    echo =============================================================
    rsync -Cavz --delete-after -e "ssh -p$remotePort" $gitRakeBackups/ $remoteUser@$remoteServer:$remoteDest
}

rsyncKey() {
# rsync up with specific key
    echo =============================================================
    echo Start rsync to rsync.net/backup with specific key
    echo =============================================================
    echo "rsync -Cavz --delete-after -e "ssh -i $sshKeyPath -p$remotePort" $gitRakeBackups/ $remoteUser@$remoteServer:$remoteDest"
}

rsyncDaemon() {
# rsync up with specific key
    echo =============================================================
    echo Start rsync to rsync.net/backup in daemon mode
    echo =============================================================
    rsync -Cavz --port=$remotePort --password-file=$rsync_password_file --delete-after /$gitRakeBackups/ $remoteUser@$remoteServer::$remoteModule
}

###
## Git'r done
#

rakeBackup
checkSize

# go back to where we came from
cd $PDIR

# check for a config file, otherwise don't copy to another place
if [ -e $confFile -a -r $confFile ]
then
	# read the confile
	source $confFile
	
	# if the $remoteModule is set run rsyncDaemon
	if [[ $remoteModule != "" ]]
	then
		rsyncDaemon
	# no Daemon so lets see if we are using a special key
	else if [ -e $sshKeyPath -a -r $sshKeyPath ]
		then
			rsyncKey
		else
			# use the defualt 
			rsyncUp
		fi
	fi
	
fi

###
## Exit gracefully
#
exit 0
