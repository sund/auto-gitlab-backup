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
    rsync -Cavz --delete-after /$gitRakeBackups/ $remoteUser@$remoteServer:$remoteDest
}

rsyncKey() {
# rsync up with specific key
    echo =============================================================
    echo Start rsync to rsync.net/backup with key
    echo =============================================================
    rsync -Cavz --delete-after -e "ssh -i $sshKeyPath" /$gitRakeBackups/ $remoteUser@$remoteServer:$remoteDest
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
	if [ -e $sshKeyPath -a -r $sshKeyPath ]
	then
	# if the keyfile exists (using a special one) then use it
		source $confFile
		rsyncKey
	else
	# use the default
		source $confFile
		rsyncUp
	fi
fi

###
## Exit gracefully
#
exit 0
