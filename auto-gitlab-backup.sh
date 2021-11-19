#!/bin/bash

################################
#
# autogitbackup.sh
# -----------------------------
#
# this script backups
# /var/opt/gitlab/backups to
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
gitlab_rails="/opt/gitlab/embedded/service/gitlab-rails"
PDIR=$(dirname $(readlink -f $0))
dateStamp=`date +"%F %H:%m:%S"`
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
  echo "Using RVM environment file:"
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

archiveConfig() {
  echo ===== Archiving Configs =====
  if [[ $backupConfigs = 1 ]]
  then
    if [[ -w $localConfDir ]]
    then
      tar -czf "$localConfDir/gitlabConf-$dateStamp.tgz" $localConfig $localsshkeys

      # remove files not within 3 days
      find $localConfDir -type f -mtime +3 -exec rm -v {} \;

    else
      echo "$localConfDir is not writable."
    fi
  else
    echo "Local config backups aren't enabled!"
  fi
}

rakeBackup() {
    echo ===== raking a backup =====
    cd $gitRakeBackups

    if [[ $quietRake == 1 ]]
    then
      rakeBackup="gitlab-rake gitlab:backup:create CRON=1"
    else
      rakeBackup="gitlab-rake gitlab:backup:create"
    fi

    $rakeBackup
}

rsyncUp() {
# rsync up with default key
    echo =============================================================
    echo -e "Start rsync to \n$remoteServer:$remoteDest\ndefault key\n"
    rsync -Cavz --delete-after -e "ssh -p$remotePort" $gitRakeBackups/ $remoteUser@$remoteServer:$remoteDest

    # config rsync
    if [ ! -z $remoteConfDest ]
    then
      echo ===== rsync a config backup =====
      echo =============================================================
      echo -e "Start rsync to \n$remoteServer:$remoteConfDest\ndefault key\n"
      rsync -Cavz --delete-after -e "ssh -p$remotePort" $localConfDir/ $remoteUser@$remoteServer:$remoteConfDest
    fi
}

rsyncUp_dryrun() {
# rsync up with default key
    echo =============================================================
    echo -e "Start dry run rsync to \n$remoteServer:$remoteDest\ndefault key\n"
    rsync --dry-run -Cavz --delete-after -e "ssh -p$remotePort" $gitRakeBackups/ $remoteUser@$remoteServer:$remoteDest

    # config rsync
    if [ ! -z $remoteConfDest ]
    then
      echo ===== rsync a config backup =====
      echo =============================================================
      echo -e "Start dry run rsync to \n$remoteServer:$remoteConfDest\ndefault key\n"
      rsync --dry-run -Cavz --delete-after -e "ssh -p$remotePort" $localConfDir/ $remoteUser@$remoteServer:$remoteConfDest
    fi
}

rsyncKey() {
# rsync up with specific key
    echo =============================================================
    echo -e "Start rsync to \n$remoteServer:$remoteDest\nwith specific key\n"
    rsync -Cavz --delete-after -e "ssh -i $sshKeyPath -p$remotePort" $gitRakeBackups/ $remoteUser@$remoteServer:$remoteDest

    # config rsync
    if [ ! -z $remoteConfDest ]
    then
      echo ===== rsync a config backup =====
      echo =============================================================
      echo -e "Start rsync to \n$remoteServer:$remoteConfDest\ndefault key\n"
      rsync -Cavz --delete-after -e "ssh -p$remotePort" $localConfDir/ $remoteUser@$remoteServer:$remoteConfDest
    fi
}

rsyncKey_dryrun() {
# rsync up with specific key
    echo =============================================================
    echo -e "Start dry run rsync to \n$remoteServer:$remoteDest\nwith specific key\n"
    rsync --dry-run -Cavz --delete-after -e "ssh -i $sshKeyPath -p$remotePort" $gitRakeBackups/ $remoteUser@$remoteServer:$remoteDest

    # config rsync
    if [ ! -z $remoteConfDest ]
    then
      echo ===== rsync a config backup =====
      echo =============================================================
      echo -e "Start rsync to \n$remoteServer:$remoteConfDest\ndefault key\n"
      rsync --dry-run -Cavz --delete-after -e "ssh -p$remotePort" $localConfDir/ $remoteUser@$remoteServer:$remoteConfDest
    fi
}

rsyncDaemon() {
# rsync up with specific key
    echo =============================================================
    echo -e "Start rsync to \n$remoteUser@$remoteServer:$remoteModule\nin daemon mode\n"
    rsync -Cavz --port=$remotePort --password-file=$rsync_password_file --delete-after /$gitRakeBackups/ $remoteUser@$remoteServer::$remoteModule

    # config rsync
    if [ ! -z $remoteConfDest ]
    then
      echo ===== rsync a config backup =====
      echo =============================================================
      echo -e "Start rsync to \n$remoteServer:$remoteConfDest\ndefault key\n"
      rsync -Cavz --delete-after -e "ssh -p$remotePort" $localConfDir/ $remoteUser@$remoteServer:$remoteConfDest
    fi
}

rsyncDaemon_dryrun() {
# rsync up with specific key
    echo =============================================================
    echo -e "Start rsync to \n$remoteUser@$remoteServer:$remoteModule\nin daemon mode\n"
    rsync --dry-run -Cavz --port=$remotePort --password-file=$rsync_password_file --delete-after /$gitRakeBackups/ $remoteUser@$remoteServer::$remoteModule

    # config rsync
    if [ ! -z $remoteConfDest ]
    then
      echo ===== rsync a config backup =====
      echo =============================================================
      echo -e "Start rsync to \n$remoteServer:$remoteConfDest\ndefault key\n"
      rsync --dry-run -Cavz --delete-after -e "ssh -p$remotePort" $localConfDir/ $remoteUser@$remoteServer:$remoteConfDest
    fi
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
	echo "Version $(git describe --abbrev=0 --tags --always), commit #$(git log --pretty=format:'%h' -n 1)."
}

usage() {
	echo ""
	echo "Usage:"
	echo "$0 -h | --help this help page"
	echo "$0 -d | --dry-run test rsync operations; no data transmitted."
	echo "$0 no options, perform backup, rsync or b2 operations."
	echo ""
}

areWeRoot() {
  ## test for running as root
  if [[ "$UID" -ne "$ROOT_UID" ]];
  then
  	echo "You must run this script as root to run."
      if [[ $1 ==  -d ]] || [[ $1 == --dry-run ]]
        then
        echo "...even to dryrun as we need to access the backup dir."
      fi
    usage
  	exit 1
  fi
}

b2Sync() {
  # b2 sync
  echo =============================================================
  echo -e "Start b2 sync of $gitRakeBackups to bucket $b2Bucketname \n"

  if [[ $b2blaze == 0 ]]
  then
    echo "Backblaze b2 file operations not enabled!"
  else

    # test for b2 command
    if type b2 > /dev/null 2>&1
    then
      # bucketname set and readable
      if [ ! -z $b2Bucketname ]
      then
        if test -r "$gitRakeBackups" -a -d "$gitRakeBackups"
        then
          b2 sync --noProgress --keepDays $b2keepDays --replaceNewer $gitRakeBackups/ b2://$b2Bucketname/backups/
        else
          echo " gitRakeBackups ($gitRakeBackups) not readable."
        fi
      else
        echo " b2Bucketname not set."
      fi
    else
      echo " b2 command not found!"
    fi

  fi
echo ""
}

b2SyncProgress() {
  # b2 sync
  echo =============================================================
  echo -e "Start b2 sync of $gitRakeBackups to bucket $b2Bucketname \n"

  if [[ $b2blaze == 0 ]]
  then
    echo "Backblaze b2 file operations not enabled!"
  else

    # test for b2 command
    if type b2 > /dev/null 2>&1
    then
      # bucketname set and readable
      if [ ! -z $b2Bucketname ]
      then
        if test -r "$gitRakeBackups" -a -d "$gitRakeBackups"
        then
          b2 sync --keepDays $b2keepDays --replaceNewer $gitRakeBackups/ b2://$b2Bucketname/backups/
        else
          echo " gitRakeBackups ($gitRakeBackups) not readable."
        fi
      else
        echo " b2Bucketname not set."
      fi
    else
      echo " b2 command not found!"
    fi

  fi
echo ""
}

b2SyncConf() {
  # b2 sync
  echo =============================================================
  echo -e "Start b2 sync of /etc/gitlab to bucket $b2Bucketname/configs/ \n"

  if [[ $backupConfigs == 1 ]]
  then
    if [[ $b2blaze == 0 ]]
    then
      echo "Backblaze b2 file operations not enabled!"
    else

      # test for b2 command
      if type b2 > /dev/null 2>&1
      then
        # bucketname set and readable
        if [ ! -z $b2Bucketname ]
        then
          if test -r "$gitRakeBackups" -a -d "$gitRakeBackups"
          then
            b2 sync --noProgress --keepDays $b2keepDays --replaceNewer /etc/gitlab/ b2://$b2Bucketname/configs/
          else
            echo " gitRakeBackups ($gitRakeBackups) not readable."
          fi
        else
          echo " b2Bucketname not set."
        fi
      else
        echo " b2 command not found!"
      fi

    fi
  fi
echo ""
}

b2SyncConfProgress() {
  # b2 sync
  echo =============================================================
  echo -e "Start b2 sync of /etc/gitlab to bucket $b2Bucketname/configs/ \n"

  if [[ $backupConfigs == 1 ]]
  then
    if [[ $b2blaze == 0 ]]
    then
      echo "Backblaze b2 file operations not enabled!"
    else

      # test for b2 command
      if type b2 > /dev/null 2>&1
      then
        # bucketname set and readable
        if [ ! -z $b2Bucketname ]
        then
          if test -r "$gitRakeBackups" -a -d "$gitRakeBackups"
          then
            b2 sync --keepDays $b2keepDays --replaceNewer /etc/gitlab/ b2://$b2Bucketname/configs/
          else
            echo " gitRakeBackups ($gitRakeBackups) not readable."
          fi
        else
          echo " b2Bucketname not set."
        fi
      else
        echo " b2 command not found!"
      fi

    fi
  fi
echo ""
}

confFileExist() {
  # read the conffile
  if [ -e $confFile -a -r $confFile ]
  then
  	source $confFile
  	echo "Parsing config file..."
          rvm_ENV
  else
  	echo "No confFile found; Remote copy DISABLED."
  fi
}

###
## Git'r done
#

case $1 in
	-h|--help )
		usage
		;;
	-d|--dry-run )
    areWeRoot $1
    confFileExist
    archiveConfig
		##test ssh and rsync functions
    if [[ $remoteModule != "" ]]
      then
      rsyncDaemon_dryrun
      b2SyncProgress
      # no Daemon so lets see if we are using a special key
    else if [ -e $sshKeyPath -a -r $sshKeyPath ] && [[ $sshKeyPath != "" ]]
      then
      rsyncKey_dryrun
      b2SyncProgress
      sshQuotaKey
    else if [[ $remoteServer != "" ]]
      then
      # use the default
      rsyncUp_dryrun
      b2SyncProgress
      sshQuota
    fi
    fi
    fi
		;;
	* )
    areWeRoot $1
    confFileExist
    # perform backup
    rakeBackup
    archiveConfig
    checkSize
    # go back to where we came from
    cd $PDIR
    # if the $remoteModule is set run rsyncDaemo
    ## here we assume variables are set right and only check when needed.
    if [[ $remoteModule != "" ]]
      then
      rsyncDaemon
      b2Sync
      # no Daemon so lets see if we are using a special key
    else if [ -e $sshKeyPath -a -r $sshKeyPath ] && [[ $sshKeyPath != "" ]]
      then
      rsyncKey
      b2Sync
      sshQuotaKey
    else if [[ $remoteServer != "" ]]
      then
      # use the default
      rsyncUp
      b2Sync
      sshQuota
    else if [[ $b2blaze == "1" ]]
      then
      # use b2Sync only
      b2Sync
    fi
    fi
    fi
    fi
    ;;
esac

## temp
if [[ $b2blaze != 0 ]]
  then
  b2 get-account-info
  b2 list-buckets
fi

# Print version
printScriptver

###
## Exit gracefully
#
exit 0
