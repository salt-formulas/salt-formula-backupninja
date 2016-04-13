#!/bin/bash

if [ $EUID -ne 0 ]; then
    exec /usr/bin/sudo $0 $*
fi

export KRB5CCNAME=/tmp/krb5cc_duplicity_salt
DUPLICITY_ARGS="--progress $(grep -E '^options\ ?=' /etc/backup.d/200.backup.dup | sed 's,options[\ ]*=[\ ]*,,g')"
BACKUP_URL="$(grep -E '^desturl\ ?=' /etc/backup.d/200.backup.dup | sed 's,desturl[\ ]*=[\ ]*,,g')"

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
    [ -f /etc/backup.d/100.kinit.sh ] && . /etc/backup.d/100.kinit.sh
}

action_cleanup() {
    trap true INT TERM EXIT
    [ -f /etc/backup.d/999.kdestroy.sh ] && . /etc/backup.d/999.kdestroy.sh
}

restore() {
    RESTORE_ARGS=""
    [ ! -z "$FILE" ] && RESTORE_ARGS="${RESTORE_ARGS} --file-to-restore=${FILE}"
    duplicity ${DUPLICITY_ARGS} restore ${BACKUP_URL} "${DEST}" ${RESTORE_ARGS}
}

status() {
    duplicity ${DUPLICITY_ARGS} collection-status ${BACKUP_URL}
}

nagios() {
    TOL=$1
    EXITVAL=2
    read -ra dup_status <<< $(status)

    if [[ -n ${dup_status[@]} ]]; then
        read -ra err_msg <<< $(echo ${dup_status[@]} | sed -e 's/\<No orphaned or incomplete backup sets found\>//g')

        if [ ${#dup_status[@]} -ne ${#err_msg[@]} ]; then
            EXITVAL=0
        else
            exit_critical "incomplete backup found"
        fi
    else
        exit_critical "duplicity not working correctly"
    fi

    LAST=$(date -d "$(echo ${dup_status[@]} | sed -n -e 's/^.*Chain end time: //p' | awk '{print $1,$2,$3,$4,$5}')" +"%s")
    TODATE=$(date +"%s")

    if [ $[TODATE-$TOL] -gt $LAST ]; then
        exit_critical "Last backup $[(TODATE-LAST)/3600] hours ago."
    else
        exit_ok "Last backup: $LAST"
    fi
}

exit_critical() {
    echo "CRITICAL: $*"
    exit 2
}

exit_ok() {
    echo "OK: $*"
    exit 0
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
    echo "  nagios      - nagios check"
    echo "               Usage: duplicity_salt.sh nagios x_hours_back"
    exit 1
}

case $1 in
    restore) action_prepare && restore ;;
    status) action_prepare && status ;;
    nagios)
        TOL=$[$2*3600]
        action_prepare && nagios $TOL
        ;;
    list-files) action_prepare && list_files ;;
    *) usage ;;
esac
