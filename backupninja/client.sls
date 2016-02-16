{%- from "backupninja/map.jinja" import client, service_grains with context %}
{%- if client.enabled %}

{%- if pillar.postgresql is defined or pillar.mysql is defined %}
include:
{%- if pillar.postgresql is defined %}
- postgresql
{%- endif %}
{%- if pillar.mysql is defined %}
- mysql
{%- endif %}
{%- endif %}

backupninja_packages:
  pkg.installed:
  - names: {{ client.pkgs }}

backups_dir:
  file.directory:
  - name: /var/backups
  - user: root
  - group: root

{%- if pillar.postgresql is defined %}

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
    - service: postgresql_service

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
    - service: mysql_service

{%- endif %}

{%- for backup_name, backup in service_grains.backupninja.backup.iteritems() %}
{%- set backup_index = loop.index %}
{%- for action in backup.get('actions', []) %}

backupninja_{{ backup_name }}_action_{{ loop.index }}:
  file.managed:
    - name: /etc/backup.d/0{{ backup_index }}.{{ backup_name }}_{{ loop.index }}.{{ backup.get('handler', 'sh') }}
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

backupninja_client_grains_dir:
  file.directory:
  - name: /etc/salt/grains.d
  - mode: 700
  - makedirs: true
  - user: root

backupninja_client_grain:
  file.managed:
  - name: /etc/salt/grains.d/backupninja
  - source: salt://backupninja/files/backupninja.grain
  - template: jinja
  - user: root
  - mode: 600
  - require:
    - file: backupninja_client_grains_dir

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
  - template: jinja
  - mode: 700
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

backupninja_remote_handler:
  file.absent:
  - name: /etc/backup.d/200.{{ client.target.engine }}
  - require:
    - pkg: backupninja_packages

backupninja_remote_handler_{{ client.target.engine }}:
  file.managed:
  - name: /etc/backup.d/200.backup.{{ client.target.engine }}
  - source: salt://backupninja/files/{{ client.target.engine }}.conf
  - template: jinja
  - mode: 600
  - require:
    - pkg: backupninja_packages

{%- if client.target.auth.gss is defined %}
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
