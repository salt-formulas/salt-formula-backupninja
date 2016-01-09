{%- from "backupninja/map.jinja" import client with context %}
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

{%- if pillar.postgresql is defined %}

backupninja_postgresql_handler:
  file.managed:
  - name: /etc/backup.d/100.pgsql
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

backupninja_client_grains_dir:
  file.directory:
  - name: /etc/salt/grains.d
  - mode: 700
  - makedirs: true
  - user: root

{%- set service_grains = {'backupninja': {'backup': {}}} %}
{%- for service_name, service in pillar.items() %}
{%- if service.get('_support', {}).get('backupninja', {}).get('enabled', False) %}
{%- set grains_fragment_file = service_name+'/meta/backupninja.yml' %}
{%- macro load_grains_file() %}{% include grains_fragment_file %}{% endmacro %}
{%- set grains_yaml = load_grains_file()|load_yaml %}
{%- set _dummy = service_grains.backupninja.backup.update(grains_yaml.backup) %}
{%- endif %}
{%- endfor %}

backupninja_client_grain:
  file.managed:
  - name: /etc/salt/grains.d/backupninja
  - source: salt://backupninja/files/backupninja.grain
  - template: jinja
  - user: root
  - mode: 600
  - defaults:
    service_grains: {{ service_grains|yaml }}
  - require:
    - file: backupninja_client_grains_dir

{%- if client.target is defined %}

{%- if client.target.engine in ["s3",] %}
backupninja_duplicity_packages:
  pkg.installed:
  - names:
    - duplicity
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

{%- for backup_name, backup in service_grains.backupninja.backup.iteritems() %}
{%- if backup.fs_includes is defined %}
backupninja_remote_handler_{{ backup_name }}:
  file.managed:
  - name: /etc/backup.d/200.{{ backup_name }}.{{ client.target.engine }}
  - source: salt://backupninja/files/{{ client.target.engine }}.conf
  - template: jinja
  - mode: 600
  - defaults:
      backup: {{ backup }}
  - require:
    - pkg: backupninja_packages
{%- endif %}
{%- endfor %}

{%- endif %}

{%- endif %}
