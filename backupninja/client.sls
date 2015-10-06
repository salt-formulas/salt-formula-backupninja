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

{%- for service in client.supported_services %}
{%- if service in grains.get('roles', []) %}

{%- for service_group in service.split('.') %}
{%- if loop.first %}

backupninja_remote_handler_{{ service|replace('.', '_') }}:
  file.managed:
  - name: /etc/backup.d/20{{ loop.index }}.{{ service_group }}.{{ client.target.engine }}
  - source: salt://backupninja/files/{{ client.target.engine }}.conf
  - template: jinja
  - mode: 600
  - defaults:
      service_config: {{ service_group }}/files/backupninja.conf
      {%- if client.config_monkeypatch is defined and client.config_monkeypatch %}
      service_config_monkeypatch: {{ service_group }}/files/backupninja_monkeypatch.conf
      {%- endif %}
  - require:
    - pkg: backupninja_packages

{%- endif %}
{%- endfor %}

{%- endif %}
{%- endfor %}

{%- endif %}

{%- endif %}