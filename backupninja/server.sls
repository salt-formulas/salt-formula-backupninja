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

{{ server.home_dir }}:
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

{%- set clients = [] %}
{%- if server.restrict_clients %}
  {%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').iteritems() %}
    {%- if node_grains.get('backupninja', {}).get('client') %}
    {%- set client = node_grains.backupninja.get("client") %}
      {%- if client.get('addresses') and client.get('addresses', []) is iterable %}
        {%- for address in client.addresses %}
          {%- do clients.append(address|string) %}
        {%- endfor %}
      {%- endif %}
    {%- endif %}
  {%- endfor %}
{%- endif %}

backupninja_key_{{ key.key }}:
  ssh_auth.present:
  - user: backupninja
  - name: {{ key.key }}
  - options:
    - no-pty
{%- if clients %}
    - from="{{ clients|join(',') }}"
{%- endif %}
  - require:
    - file: {{ server.home_dir }}

{%- endif %}

{%- endfor %}

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