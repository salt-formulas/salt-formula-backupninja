
===================
Backupninja formula
===================

Backupninja allows you to coordinate system backup by dropping a few simple
configuration files into /etc/backup.d/. Most programs you might use for
making backups don't have their own configuration file format.

Backupninja provides a centralized way to configure and schedule many
different backup utilities. It allows for secure, remote, incremental
filesytem backup (via rdiff-backup), compressed incremental data, backup
system and hardware info, encrypted remote backups (via duplicity), safe
backup of MySQL/PostgreSQL databases, subversion or trac repositories, burn
CD/DVDs or create ISOs, incremental rsync with hardlinking.


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

Backup client with ssh/rsync remote target with specific rsync options

.. code-block:: yaml

    backupninja:
      client:
        enabled: true
        target:
          engine: rsync
          engine_opts: "-av --delete --recursive --safe-links"
          home_dir: /srv/volumes/backup/backupninja
          host: 10.10.10.208
          user: backupninja

Backup client with s3 remote target

.. code-block:: yaml

    backupninja:
      client:
        enabled: true
        target:
          engine: dup
          url: s3+http://bucket-name/folder-name
          auth:
            awsaccesskeyid: awsaccesskeyid
            awssecretaccesskey: awssecretaccesskey

Backup client with webdav target

.. code-block:: yaml

    backupninja:
      client:
        enabled: true
        target:
          engine: dup
          url: webdavs://backup.cloud.example.com/box.example.com/
          auth:
            gss:
              principal: host/${linux:network:fqdn}
              keytab: /etc/krb5.keytab

Backup client with exact backup times


.. note:: This settings will configure global backupninja backup to be
   triggered at exactly set times.

.. code-block:: yaml

    backupninja:
      client:
        enabled: true
        auto_backup_disabled: false
        backup_times:
          day_of_week: 1
          hour: 2
          minute: 32

.. note:: This will trigger backup every monday at 2:32 AM.

.. code-block:: yaml

    backupninja:
      client:
        enabled: true
        auto_backup_disabled: false
        backup_times:
          day_of_month: 24
          hour: 14
          minute: 12

.. note:: This will trigger backup every 24th day of every month at 14:12 (2:12 PM).

.. note:: Available parameters:
   ``day_of_week`` (0, 3, 6 ...). If not set, defaults to '*'.
   ``day_of_month`` (20, 25, 12, ...). If not set, defaults to '*'.
     Only ``day_of_week`` or ``day_of_month`` can be defined at the same time.
   ``hour`` (1, 10, 15, ...). If not defined, defaults to `1`. Uses 24 hour format.
   ``minute`` (5, 10, 59, ...). If not defined, defaults to `00`.

..note:: Parameter ``auto_backup_disabled`` is optional. It disables automatic
  backup when set to true. It's set to ``false``by default when not defined.

Backup server rsync/rdiff

.. code-block:: yaml

    backupninja:
      server:
        enabled: true
        rdiff: true
        key:
          client1.domain.com:
            enabled: true
            key: ssh-key

Backup server without strict client policy restriction

.. code-block:: yaml

    backupninja:
      server:
        restrict_clients: false

Backup client with local storage

.. code-block:: yaml

    backupninja:
      client:
        enabled: true
        target:
          engine: local

More information
================

* https://labs.riseup.net/code/projects/backupninja/wiki/Configuration
* http://www.debian-administration.org/articles/351
* http://duncanlock.net/blog/2013/08/27/comprehensive-linux-backups-with-etckeeper-backupninja/
* https://github.com/riseuplabs/puppet-backupninja
* http://www.ushills.co.uk/2008/02/backup-with-backupninja.html


Documentation and Bugs
======================

To learn how to install and update salt-formulas, consult the documentation
available online at:

    http://salt-formulas.readthedocs.io/

In the unfortunate event that bugs are discovered, they should be reported to
the appropriate issue tracker. Use Github issue tracker for specific salt
formula:

    https://github.com/salt-formulas/salt-formula-backupninja/issues

For feature requests, bug reports or blueprints affecting entire ecosystem,
use Launchpad salt-formulas project:

    https://launchpad.net/salt-formulas

You can also join salt-formulas-users team and subscribe to mailing list:

    https://launchpad.net/~salt-formulas-users

Developers wishing to work on the salt-formulas projects should always base
their work on master branch and submit pull request against specific formula.

    https://github.com/salt-formulas/salt-formula-backupninja

Any questions or feedback is always welcome so feel free to join our IRC
channel:

    #salt-formulas @ irc.freenode.net
