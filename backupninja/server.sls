{%- from "backupninja/map.jinja" import server with context %}
{%- if server.enabled %}

backupninja_server_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

backupninja_user:
  user.present:
  - name: backupninja
  - system: true
  - home: {{ server.home_dir }}
  - groups:
    - backupninja

backupninja_group:
  group.present:
  - name: backupninja
  - system: true
  - require_in:
    - user: backupninja_user

{{ server.home_dir }}:
  file.directory:
  - mode: 700
  - user: backupninja
  - group: backupninja
  - makedirs: true
  - require:
    - user: backupninja_user
    - pkg: backupninja_server_packages

{{ server.home_dir }}/.ssh:
  file.directory:
  - mode: 700
  - user: backupninja
  - group: backupninja
  - require:
    - file: {{ server.home_dir }}

{{ server.home_dir }}/.ssh/authorized_keys:
  file.managed:
  - user: backupninja
  - group: backupninja
  - template: jinja
  - source: salt://backupninja/files/authorized_keys
  - require:
    - file: {{ server.home_dir }}
    - file: {{ server.home_dir }}/.ssh

{%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').iteritems() %}

{%- for backup_name, backup in node_grains.get('backupninja', {}).get('backup', {}).iteritems() %}
{%- for fs_include in backup.fs_includes %}

{{ server.home_dir }}/{{ node_name }}{{ fs_include }}:
  file.directory:
  - mode: 700
  - user: backupninja
  - group: backupninja
  - makedirs: true
  - require:
    - user: backupninja_user
    - pkg: backupninja_server_packages

{%- endfor %}
{%- endfor %}

{%- endfor %}

{%- endif %}
