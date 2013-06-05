## AutoGITBackup

----
A script to use gitlab's own backup ```rake``` command on a cron schedule and rsync to another server if wanted.

#### Clone

clone to your directory of choice. I usually use ```/usr/local/sbin```

#### Set up gitlab to expire backups

Change ```config.yml``` to expire backups

_remove the # from ```keep_time```_

```ruby
## Backup settings
  backup:
    path: "tmp/backups"   # Relative paths are relative to Rails.root (default: tmp/backups/)
    keep_time: 604800 # a week
    # keep_time: 604800   # default: 0 (forever) (in seconds)
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
```

#### cron settings

Example for crontab to run at 5:05am everyday. 

```bash
5 5 * * * /usr/local/sbin/auto-gitlab-backup/auto-gitlab-backup.sh
```

