
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
