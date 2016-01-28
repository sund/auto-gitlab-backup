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
rakeBackup="gitlab-rake gitlab:backup:create"
rakeCIBackup="gitlab-ci-rake backup:create"

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
    if [[ $enableCIBackup == "true" || $enableCIBackup = 1 ]]
    then
      echo `du -hs "$gitRakeCIBackups"`
    fi
    echo
}

archiveConfig() {
  echo ===== Archiving Configs =====
  if [ -w $localConfDir ]
  then
    tar -czf "$localConfDir/gitlabConf-$dateStamp.tgz" $localConfig $localsshkeys

    # remove files not within 3 days
    find $localConfDir -type f -mtime +3 -exec rm {} \;

  else
    echo "Local configs aren't enabled or $localConfDir is not writable."
  fi
}

rakeBackup() {
    echo ===== raking a backup =====
    cd $gitRakeBackups
    $rakeBackup
}

rakeCIBackup() {
  if [[ $enableCIBackup == "true" || $enableCIBackup = 1 ]]
  then
    echo ===== raking a CI backup =====
    cd $gitRakeCIBackups
    $rakeCIBackup
  fi
}

rsyncUp() {
# rsync up with default key
    echo =============================================================
    echo -e "Start rsync to \n$remoteServer:$remoteDest\ndefault key\n"
    rsync -Cavz --delete-after -e "ssh -p$remotePort" $gitRakeBackups/ $remoteUser@$remoteServer:$remoteDest

    # rsync CI backup
    if [[ $enableCIBackup == "true" || $enableCIBackup = 1 ]]
    then
      echo ===== rsync a CI backup =====
      echo =============================================================
      echo -e "Start rsync to \n$remoteServer:$ciRemoteDest\ndefault key\n"
      rsync -Cavz --delete-after -e "ssh -p$remotePort" $gitRakeCIBackups/ $remoteUser@$remoteServer:$ciRemoteDest
    fi

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

    # rsync CI backup
    if [[ $enableCIBackup == "true" || $enableCIBackup = 1 ]]
    then
      echo ===== rsync a CI backup =====
      echo =============================================================
      echo -e "Start rsync to \n$remoteServer:$ciRemoteDest\ndefault key\n"
      rsync --dry-run -Cavz --delete-after -e "ssh -p$remotePort" $gitRakeCIBackups/ $remoteUser@$remoteServer:$ciRemoteDest
    fi

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

    # rsync CI backup
    if [[ $enableCIBackup == "true" || $enableCIBackup = 1 ]]
    then
      echo ===== rsync a CI backup =====
      echo -e "Start rsync to \n$remoteServer:$ciRemoteDest\nwith specific key\n"
      rsync -Cavz --delete-after -e "ssh -i $sshKeyPath -p$remotePort" $gitRakeCIBackups/ $remoteUser@$remoteServer:$ciRemoteDest
    fi

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

    # rsync CI backup
    if [[ $enableCIBackup == "true" || $enableCIBackup = 1 ]]
    then
      echo ===== rsync a CI backup =====
      echo -e "Start rsync to \n$remoteServer:$ciRemoteDest\nwith specific key\n"
      rsync --dry-run -Cavz --delete-after -e "ssh -i $sshKeyPath -p$remotePort" $gitRakeCIBackups/ $remoteUser@$remoteServer:$ciRemoteDest
    fi

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

    # rsync CI backup
    if [[ $enableCIBackup == "true" || $enableCIBackup = 1 ]]
    then
      echo ===== rsync a CI backup =====
      echo =============================================================
      echo -e "Start rsync to \n$remoteUser@$remoteServer:$remoteCIModule\nin daemon mode\n"
      rsync -Cavz --port=$remotePort --password-file=$rsync_password_file --delete-after /$gitRakeCIBackups/ $remoteUser@$remoteServer::$remoteCIModule
    fi

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

    # rsync CI backup
    if [[ $enableCIBackup == "true" || $enableCIBackup = 1 ]]
    then
      echo ===== rsync a CI backup =====
      echo =============================================================
      echo -e "Start rsync to \n$remoteUser@$remoteServer:$remoteCIModule\nin daemon mode\n"
      rsync --dry-run -Cavz --port=$remotePort --password-file=$rsync_password_file --delete-after /$gitRakeCIBackups/ $remoteUser@$remoteServer::$remoteCIModule
    fi

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
	echo "$0 no options, perform backup and rsync."
	echo ""
}

areWeRoot() {
  ## test for running as root
  if [[ "$UID" -ne "$ROOT_UID" ]];
  then
  	echo "You must run this script as root to run."
      if [[ $1 ==  -d ]] || [[ $1 == --dry-run ]]
        then
        echo "...even to dryrun as we need to acccess the backup dir."
      fi
    usage
  	exit 1
  fi
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
		##test ssh and rsync functions
    if [[ $remoteModule != "" ]]
      then
      rsyncDaemon_dryrun
      # no Daemon so lets see if we are using a special key
    else if [ -e $sshKeyPath -a -r $sshKeyPath ] && [[ $sshKeyPath != "" ]]
      then
      rsyncKey_dryrun
      sshQuotaKey
    else if [[ $remoteServer != "" ]]
      then
      # use the defualt
      rsyncUp_dryrun
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
    rakeCIBackup
    archiveConfig
    checkSize
    # go back to where we came from
    cd $PDIR
    # if the $remoteModule is set run rsyncDaemo
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
    ;;
esac

# Print version
printScriptver

###
## Exit gracefully
#
exit 0
