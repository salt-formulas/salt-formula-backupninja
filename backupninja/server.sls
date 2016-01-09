{%- from "backupninja/map.jinja" import server with context %}
{%- if server.enabled %}

backupninja_server_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

backupninja_user:
  user.present:
  - name: backupninja
  - system: true
  - home: /srv/backupninja

/srv/backupninja:
  file.directory:
  - mode: 700
  - user: backupninja
  - group: backupninja
  - makedirs: true
  - require:
    - user: backupninja_user
    - pkg: backupninja_server_packages

{%- for key_name, key in server.key.iteritems() %}

{%- if key.get('enabled', False) %}

backupninja_key_{{ key.key }}:
  ssh_auth.present:
  - user: backupninja
  - name: {{ key.key }}
  - require:
    - file: /srv/backupninja

{%- endif %}

{%- endfor %}

{%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').iteritems() %}

/srv/backupninja/{{ node_name }}:
  file.directory:
  - mode: 700
  - user: backupninja
  - group: backupninja
  - makedirs: true
  - require:
    - user: backupninja_user
    - pkg: backupninja_server_packages

{%- for backup_name, backup in node_grains.get('backupninja', {}).get('backup', {}).iteritems() %}
{%- for fs_include in backup.fs_includes %}

/srv/backupninja/{{ node_name }}{{ fs_include }}:
  file.directory:
  - mode: 700
  - user: backupninja
  - group: backupninja
  - makedirs: true
  - require:
    - file: /srv/backupninja/{{ node_name }}

{%- endfor %}
{%- endfor %}

{%- endfor %}

{%- endif %}