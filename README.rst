
===========
Backupninja
===========

Backupninja allows you to coordinate system backup by dropping a few simple configuration files into /etc/backup.d/. Most programs you might use for making backups don't have their own configuration file format.

Backupninja provides a centralized way to configure and schedule many different backup utilities. It allows for secure, remote, incremental filesytem backup (via rdiff-backup), compressed incremental data, backup system and hardware info, encrypted remote backups (via duplicity), safe backup of MySQL/PostgreSQL databases, subversion or trac repositories, burn CD/DVDs or create ISOs, incremental rsync with hardlinking.

Sample pillars
==============

Backup client with ssh/rsync remote target

.. code-block:: yaml

    backupninja:
      client:
        enabled: true
        target:
          engine: rsync
          host: 10.10.10.208
          user: backupninja

Backup client with s3 remote target

.. code-block:: yaml

    backupninja:
      client:
        enabled: true
        target:
          engine: s3
          host: s3.domain.com
          bucket: bucketname

Backup client with webdav target

.. code-block:: yaml

    backupninja:
      client:
        enabled: true
        target:
          engine: dup
          url: webdavs://user@backup.cloud/example.com/box.example.com/
          auth: gss

Backup server rsync/rdiff

.. code-block:: yaml

    backupninja:
      server:
        enabled: true
        rdiff: true
        keys:
        - client1.domain.com

Read more
=========

* https://labs.riseup.net/code/projects/backupninja/wiki/Configuration
* http://www.debian-administration.org/articles/351
* http://duncanlock.net/blog/2013/08/27/comprehensive-linux-backups-with-etckeeper-backupninja/
* https://github.com/riseuplabs/puppet-backupninja
* http://www.ushills.co.uk/2008/02/backup-with-backupninja.html
