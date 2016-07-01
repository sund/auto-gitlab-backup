# Auto GitLab Backup

[![AGB Logo](https://raw.githubusercontent.com/sund/auto-gitlab-backup/develop/agb_logo.png)](http://sund.la/glup)

----

## Synopsis

A simple script to backup your Gitlab data. This script will copy the backup archives of your gitlab installation via rsync, or scp. Also, you can copy backups to [Backblaze’s B2 Cloud Storage service.](https://www.backblaze.com/b2/cloud-storage.html) There is also a restore script available (see below.)

It can backup and copy the ```gitlab.rb``` config file, if configured.

This script is now more omnibus-gitlab centric. Compare your config file with the template! Usage with a source install is possible but not expressly shown here.

## Installation

### Prerequisites

Deploy a working GitLab Omnibus installation and verify you can back it up with the rake task as documented in the [GitLab Documents](http://doc.gitlab.com/ce/raketasks/backup_restore.html).

For Backblaze usage, configure your system for the [Backblaze Command-Line Tool](https://www.backblaze.com/b2/docs/quick_command_line.html) Also, see the [wiki page on B2](https://github.com/sund/auto-gitlab-backup/wiki/Backblaze-B2-Command-Line-Tool).

#### Set up gitlab to expire backups

Change ```/etc/gitlab/gitlab.rb``` to expire backups

```
# backup keep time
gitlab_rails['backup_keep_time'] = 604800
```

### Installation

Clone to your directory of choice. I usually use ```/usr/local/sbin```

```
git clone git@github.com:sund/auto-gitlab-backup.git
```

### Updates

Compare the ```auto-gitlab-backup.conf.sample``` file with your own copy. Make changes as needed to ensure no errors are encountered.

### Configure

```bash
cp auto-gitlab-backup.conf.sample auto-gitlab-backup.conf
```

edit ```auto-gitlab-backup.conf```

```bash
## user account on remote server
#  likely 'git' user
remoteUser=""

## remote host
#  a backup gitlab server?
remoteServer=""

## path to an alternate ssh key, if needed.
sshKeyPath=""

## $remoteServer path for gitlab backups
remoteDest="/var/opt/gitlab/backups"

## backup gitlab configs
# change to 1 to enable
backupConfigs=“0”

## rake quietly
# change to 1 to enable quiet rake job
quietRake=0

## enable backblaze b2 sync
# change to 1 to enable
# and set bucket name
# and change b2keepDays if other than 5 days is desired
b2blaze=0
b2Bucketname=“”
b2keepDays=“5”

## set $localConfDir
# blank disables conf backups
# you can create /var/opt/gitlab/backups/configBackups --
# gitlab doesn't seem to complain with a subfolder
# in there. Plus it will rsync up with the backup.
# So you won't need to enable a separate rsync run
localConfDir="/var/opt/gitlab/backups/configBackups"

## set $remoteServer path for gitlab configs
# blank disables remote copy
# unless $localConfDir is outside /var/opt/gitlab/backups/configBackups
# you can leave this blank
remoteConfDest=""

## ssh port or 873 for rsyncd port
remotePort=22

## git user home.
#  Only change the below setting if you have git's home in a different location
gitHome="/var/opt/gitlab"

## only set below if rvm is in use and you need to source the rvm env file
# echo $(rvm env --path)
RVM_envPath=""

## only use the below settings if your destination is using rsync in daemon mode
remoteModule=""
rsync_password_file=""

## only change if configs are in different locations. (unlikely)
localConfig="/etc/gitlab"
localsshkeys="/var/opt/gitlab/.ssh"

## Check remote quota
#  change to true or 1 to enable
checkQuota="0"

```

### cron settings

Example for crontab to run at 5:05am everyday.

```bash
5 5 * * * /usr/local/sbin/auto-gitlab-backup/auto-gitlab-backup.sh
```

## Restore

*Still under development but useful*

run ```./restoreGitLab.sh -r``` and it will attempt to restore a backup. You may have to run some rake commands manually.

## Help

See the [Wiki](https://github.com/sund/auto-gitlab-backup/wiki) for more detailed instructions or submit a [Issue](https://github.com/sund/auto-gitlab-backup/issues).

## Contribute

See [Contribution Guide](https://github.com/sund/auto-gitlab-backup/blob/master/CONTRIBUTING.md) to improve this script.