{%- from "backupninja/map.jinja" import client, service_grains with context %}
{%- if client.enabled %}

backupninja_packages:
  pkg.installed:
  - names: {{ client.pkgs }}

backupninja_conf:
  file.managed:
  - name: /etc/backupninja.conf
  - source: salt://backupninja/files/backupninja.conf
  - template: jinja
  - mode: 600
  - require:
    - pkg: backupninja_packages

backups_dir:
  file.directory:
  - name: /var/backups
  - user: root
  - group: root

{%- if pillar.postgresql is defined or pillar.maas is defined %}
backupninja_postgresql_handler:
  file.managed:
  - name: /etc/backup.d/102.pgsql
  - source: salt://backupninja/files/handler/pgsql.conf
  - template: jinja
  - mode: 600
  - require_in:
    - file: backupninja_remote_handler
  - require:
    - pkg: backupninja_packages

{%- endif %}

{%- if pillar.mysql is defined %}

backupninja_mysql_handler:
  file.managed:
  - name: /etc/backup.d/101.mysql
  - source: salt://backupninja/files/handler/mysql.conf
  - template: jinja
  - mode: 600
  - require_in:
    - file: backupninja_remote_handler
  - require:
    - pkg: backupninja_packages

{%- endif %}

{%- for backup_name, backup in service_grains.backupninja.backup.iteritems() %}
{%- set backup_index = loop.index %}
{%- for action in backup.get('actions', []) %}

backupninja_{{ backup_name }}_action_{{ loop.index }}:
  file.managed:
    - name: /etc/backup.d/1{{ backup_index }}{{ loop.index }}.{{ backup_name }}.{{ backup.get('handler', 'sh') }}
    - source: salt://backupninja/files/handler/{{ backup.get('handler', 'sh') }}.conf
    - template: jinja
    - mode: 600
    - require_in:
      - file: backupninja_remote_handler
    - require:
      - pkg: backupninja_packages
    - defaults:
        backup: {{ backup }}
        action: {{ action }}

{%- endfor %}
{%- endfor %}

{%- if client.target is defined %}

{%- if client.target.engine in ["s3","dup",] %}

backupninja_duplicity_packages:
  pkg.installed:
  - names:
    - duplicity

duplicity_salt:
  file.managed:
  - name: /usr/local/sbin/duplicity_salt.sh
  - source: salt://backupninja/files/duplicity_salt.sh
  - mode: 755
  - user: root
  - group: root
  - require:
    - pkg: backupninja_packages

{%- endif %}

{%- if client.target.engine in ["rdiff",] %}

backupninja_duplicity_packages:
  pkg.installed:
  - names:
    - rdiff-backup

{%- endif %}

{%- if client.target.engine in ["rsync",] %}

manage_rsync_sh_onlyif_backupninja_1.0.1-2_is_installed:
  file.managed:
  - name: /usr/share/backupninja/rsync
  - source: salt://backupninja/files/rsync.sh
  - mode: 755
  - user: root
  - group: root
  - onlyif:
    - dpkg -l | grep backupninja | grep 1.0.1-2
  - require:
    - pkg: backupninja_packages

manage_rsync_sh_onlyif_backupninja_1.0.1-1_is_installed:
  file.managed:
  - name: /usr/share/backupninja/rsync
  - source: salt://backupninja/files/rsync.sh
  - mode: 755
  - user: root
  - group: root
  - onlyif:
    - dpkg -l | grep backupninja | grep 1.0.1-1
  - require:
    - pkg: backupninja_packages

{%- endif %}

backupninja_remote_handler:
  file.absent:
  - name: /etc/backup.d/200.{{ client.target.engine }}
  - require:
    - pkg: backupninja_packages

{%- if client.target.engine not in ["local"] %}

backupninja_remote_handler_{{ client.target.engine }}:
  file.managed:
  - name: /etc/backup.d/200.backup.{{ client.target.engine }}
  - source: salt://backupninja/files/{{ client.target.engine }}.conf
  - template: jinja
  - mode: 600
  - require:
    - pkg: backupninja_packages

{%- endif %}

{%- if client.target.auth is defined and client.target.auth.gss is defined %}

backupninja_gss_helper_kinit:
  file.managed:
  - name: /etc/backup.d/100.kinit.sh
  - source: salt://backupninja/files/gss_kinit
  - template: jinja
  - mode: 600
  - require:
    - pkg: backupninja_packages

backupninja_gss_helper_kdestroy:
  file.managed:
  - name: /etc/backup.d/999.kdestroy.sh
  - source: salt://backupninja/files/gss_kdestroy
  - template: jinja
  - mode: 600
  - require:
    - pkg: backupninja_packages

{%- endif %}

{%- endif %}

{%- endif %}
