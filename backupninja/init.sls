{%- if pillar.backupninja is defined %}
include:
{%- if pillar.backupninja.client is defined %}
- backupninja.client
{%- endif %}
{%- if pillar.backupninja.server is defined %}
- backupninja.server
{%- endif %}
{%- endif %}
