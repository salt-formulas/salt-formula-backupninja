{%- from "backupninja/map.jinja" import client, service_grains with context -%}
#!/bin/bash

DUPLICITY_ARGS="--no-encryption --progress --ssl-cacert-file={{ client.cacert_file }}"
BACKUP_URL="{{ client.target.url }}"

while getopts :f:d:v: opt; do
    case "$opt" in
        "f") FILE="${OPTARG}" ;;
        "d") DEST="${OPTARG}" ;;
        "v") set -x ;;
        "?") echo "Unknown option $opt"; exit 1 ;;
        ":") echo "No argument value for $opt"; exit 1 ;;
    esac
done
shift $((OPTIND-1))

action_prepare() {
    trap action_cleanup INT TERM EXIT
    {%- if client.target.auth.gss is defined %}
    kinit -kt {{ client.target.auth.gss.get("keytab", "/etc/krb5.keytab") }} {{ client.target.auth.gss.get("principal", "host/$(hostname -f)") }}
    {%- else %}
    return 0
    {%- endif %}
}

action_cleanup() {
    trap true INT TERM EXIT
    {%- if client.target.auth.gss is defined %}
    kdestroy || true
    {%- else %}
    return 0
    {%- endif %}
}

restore() {
    RESTORE_ARGS=""
    [ ! -z "$FILE" ] && RESTORE_ARGS="${RESTORE_ARGS} --file-to-restore=${FILE}"
    duplicity ${DUPLICITY_ARGS} restore ${BACKUP_URL} "${DEST}" ${RESTORE_ARGS}
}

status() {
    duplicity ${DUPLICITY_ARGS} collection-status ${BACKUP_URL}
}

list_files() {
    duplicity ${DUPLICITY_ARGS} list-current-files ${BACKUP_URL}
}

usage() {
    echo "Usage: $0 [restore|list-files|status]"
    echo "  restore    - restore files from backup"
    echo "               Usage: $0 restore -f [file_to_restore] -d [destination]"
    echo "  list-files - list last backup files"
    echo "  status     - show collection status"
    exit 1
}

case $1 in
    restore) action_prepare && restore ;;
    status) action_prepare && status ;;
    list-files) action_prepare && list_files ;;
    *) usage ;;
esac
