## AutoGITBackup

http://sund.la/glup

----

A collection of scripts to use omnibus-gitlab's own backup ```gitlab-rake``` command on a cron schedule and rsync to another server if wanted or to restore a backup.

#### Clone

clone to your directory of choice. I usually use ```/usr/local/sbin```

#### Set up gitlab to expire backups

Change ```/etc/gitlab/gitlab.rb``` to expire backups

```
# backup keep time
gitlab_rails['backup_keep_time'] = 604800
```

#### Configure the script for remote copy

```bash
cp auto-gitlab-backup.conf.sample auto-gitlab-backup.conf
```

edit ```auto-gitlab-backup.conf```

```bash
remoteUser="" #user account on remote server
remoteServer="" #remote host
remoteDest="" #remote path
sshKeyPath="" #path to an alternate ssh key, if needed.
remotePort=22 # ssh port
## only use the below settings if your destination is using rsync in daemon mode
remoteModule=""
rsync_password_file=""
```

#### cron settings

Example for crontab to run at 5:05am everyday. 

```bash
5 5 * * * /usr/local/sbin/auto-gitlab-backup/auto-gitlab-backup.sh
```

## restore a backup

*Still under development but useful*

run ```./restoreGitLab.sh -r``` and it will attempt to restore a backup. You may have to run some rake commands manually.