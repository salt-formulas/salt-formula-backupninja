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

{%- for key in server.keys %}

backupninja_key_{{ key.key }}:
  ssh_auth.present:
  - user: backupninja
  - name: {{ key.key }}
  - require:
    - file: /srv/backupninja

{%- endfor %}

{%- endif %}