## AutoGITBackup

http://sund.la/glup

----

A collection of scripts to use omnibus-gitlab's own backup ```gitlab-rake``` command on a cron schedule and rsync to another server, if wanted, or to restore a backup.

Also will backup and copy the Gitlab-CI DB if configured.

This script is now more omnibus-gitlab centric. Compare your config fiile with the template! Usage with a source install is possible but not expressly shown here.

#### Clone

clone to your directory of choice. I usually use ```/usr/local/sbin```

#### Set up gitlab to expire backups

Change ```/etc/gitlab/gitlab.rb``` to expire backups

```
# backup keep time
gitlab_rails['backup_keep_time'] = 604800
```

If you use the CI server, enable Ci Backup expiration

```
## Backup settings
  backup:
    path: "tmp/backups"   # Relative paths are relative to Rails.root (default: tmp/backups/)
# limit CI backup lifetime to 7 days - 604800 seconds
gitlab_ci['backup_keep_time'] = 604800
```

#### Configure the script for remote copy

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
remoteDest=""

## Using the CI server?
#  change to true or 1 to enable CI backups
enableCIBackup="0"

## $remoteServer dest for CI backups on remote
ciRemoteDest="/var/opt/gitlab/ci-backups"

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

## Check remote quota
#  change to true or 1 to enable
checkQuota="0"ÂÂ
```

#### cron settings

Example for crontab to run at 5:05am everyday.

```bash
5 5 * * * /usr/local/sbin/auto-gitlab-backup/auto-gitlab-backup.sh
```

## restore a backup

*Still under development but useful*

run ```./restoreGitLab.sh -r``` and it will attempt to restore a backup. You may have to run some rake commands manually.
