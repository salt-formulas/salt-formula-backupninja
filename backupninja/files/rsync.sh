# -*- mode: sh; sh-basic-offset: 3; indent-tabs-mode: nil; -*-
# vim: set filetype=sh sw=3 sts=3 expandtab autoindent:
#
# backupninja handler for incremental backups using rsync and hardlinks
# feedback: rhatto at riseup.net
#
#  rsync handler is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the Free
#  Software Foundation; either version 2 of the License, or any later version.
#
#  rsync handler is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License along with
#  this program; if not, write to the Free Software Foundation, Inc., 59 Temple
#  Place - Suite 330, Boston, MA 02111-1307, USA
#
# Inspiration
# -----------
#
#  - http://www.mikerubel.org/computers/rsync_snapshots/
#  - rsnap handler by paulv at bikkel.org
#  - maildir handler from backupninja
#
# Config file options
# -------------------
#
#   [general]
#   log = rsync log file
#   partition = partition where the backup lives
#   fscheck = set to 1 if fsck should run on $partition after the backup is made
#   read_only = set to 1 if $partition is mounted read-only
#   mountpoint = backup partition mountpoint or backup main folder (either local or remote)
#   backupdir = folder relative do $mountpoint where the backup should be stored (local or remote)
#   format = specify backup storage format: short, long or mirror (i.e, no rotations)
#   days = for short storage format, specify the number of backup increments (min = 2, set to 1 or less to disable)
#   keepdaily = for long storage format, specify the number of daily backup increments
#   keepweekly = for long storage format, specify the number of weekly backup increments
#   keepmonthly = for long storage format, specify the number of monthly backup increments
#   nicelevel = rsync command nice level
#   enable_mv_timestamp_bug = set to "yes" if your system isnt handling timestamps correctly
#   tmp = temp folder
#   multiconnection = set to "yes" if you want to use multiconnection ssh support
#
#   [source]
#   from = local or remote
#   host = source hostname or ip, if remote backup
#   port = remote port number (remote source only)
#   user = remote user name (remote source only)
#   testconnect = when "yes", test the connection for a remote source before backup
#   include = include folder on backup
#   exclude = exclude folder on backup
#   ssh = ssh command line (remote source only)
#   protocol = ssh or rsync (remote source only)
#   rsync = rsync program
#   rsync_options = rsync command options
#   exclude_vserver = vserver-name (valid only if vservers = yes on backupninja.conf)
#   numericids = when set to 1, use numeric ids instead of user/group mappings on rsync
#   compress = if set to 1, compress data on rsync (remote source only)
#   bandwidthlimit = set a bandwidth limit in KB/s (remote source only)
#   remote_rsync = remote rsync program (remote source only)
#   id_file = ssh key file (remote source only)
#   batch = set to "yes" to rsync use a batch file as source
#   batchbase = folder where the batch file is located
#   filelist = set yes if you want rsync to use a file list source
#   filelistbase = folder where the file list is placed
#
#   [dest]
#   dest = backup destination type (local or remote)
#   testconnect = when "yes", test the connection for a remote source before backup
#   ssh = ssh command line (remote dest only)
#   protocol = ssh or rsync (remote dest only)
#   numericids = when set to 1, use numeric ids instead of user/group mappings on rsync
#   compress = if set to 1, compress data on rsync (remote source only)
#   host = destination host name (remote destination only)
#   port = remote port number (remote destination only)
#   user = remote user name (remote destination only)
#   id_file = ssh key file (remote destination only)
#   bandwidthlimit = set a bandwidth limit in KB/s (remote destination only)
#   remote_rsync = remote rsync program (remote dest only)
#   batch = set to "yes" to rsync write a batch file from the changes
#   batchbase = folder where the batch file should be written
#   fakesuper = set to yes so rsync use the --fake-super flag (remote destination only)
#
#   [services]
#   initscripts = absolute path where scripts are located
#   service = script name to be stoped at the begining of the backup and started at its end
#
# You can also specify some system comands if you don't want the default system values:
#
#   [system]
#   rm = rm command
#   cp = cp command
#   touch = touch command
#   mv = mv command
#   fsck = fsck command
#
# You dont need to manually specify vservers using "include = /vservers".
# They are automatically backuped if vserver is set to "yes" on you backupninja.conf.
#

# function definitions

function eval_config {
  
  # system section
  
  setsection system
  getconf rm rm
  getconf cp cp
  getconf touch touch
  getconf mv mv
  getconf fsck fsck
  
  # general section
  
  setsection general
  getconf log /var/log/backup/rsync.log
  getconf partition
  getconf fscheck
  getconf read_only
  getconf mountpoint
  getconf backupdir
  getconf format short
  getconf days 7
  getconf keepdaily 5
  getconf keepweekly 3
  getconf keepmonthly 1
  getconf nicelevel 0
  getconf enable_mv_timestamp_bug no
  getconf tmp /tmp
  getconf multiconnection no
  
  # source section
  
  setsection source
  getconf from local
  getconf rsync $RSYNC
  getconf rsync_options "-av --delete --recursive"
  
  if [ "$from" == "remote" ]; then
    getconf testconnect no
    getconf protocol ssh
    getconf ssh ssh
    getconf host

    if [ "$protocol" == "ssh" ]; then
      # sshd default listen port
      getconf port 22
    else
      # rsyncd default listen port
      getconf port 873
    fi

    getconf user
    getconf bandwidthlimit
    getconf remote_rsync rsync
    getconf id_file /root/.ssh/id_dsa
  fi
  
  getconf batch no

  if [ "$batch" == "yes" ]; then
    getconf batchbase
    if [ ! -z "$batchbase" ]; then
      batch="read"
    fi
  fi

  getconf filelist no
  getconf filelistbase
  getconf include
  getconf exclude
  getconf exclude_vserver
  getconf numericids 0
  getconf compress 0
  
  # dest section
  
  setsection dest
  getconf dest local
  getconf fakesuper no
  
  if [ "$dest" == "remote" ]; then
    getconf testconnect no
    getconf protocol ssh
    getconf ssh ssh
    getconf host

    if [ "$protocol" == "ssh" ]; then
      # sshd default listen port
      getconf port 22
    else
      # rsyncd default listen port
      getconf port 873
    fi

    getconf user
    getconf bandwidthlimit
    getconf remote_rsync rsync
    getconf id_file /root/.ssh/id_dsa
  fi
  
  getconf batch no

  if [ "$batch" != "yes" ]; then
    getconf batch no
    if [ "$batch" == "yes" ]; then
      getconf batchbase
      if [ ! -z "$batchbase" ]; then
        batch="write"
      fi
    fi
  fi

  getconf numericids 0
  getconf compress 0
  
  # services section
  
  setsection services
  getconf initscripts /etc/init.d
  getconf service

  # config check

  if [ "$dest" != "local" ] && [ "$from" == "remote" ]; then
    fatal "When source is remote, destination should be local."
  fi

  if [ "$from" != "local" ] && [ "$from" != "remote" ]; then
    fatal "Invalid source $from"
  fi

  backupdir="$mountpoint/$backupdir"

  if [ "$dest" == "local" ] && [ ! -d "$backupdir" ]; then 
    fatal "Backupdir $backupdir does not exist"
  fi

  if [ ! -z "$log" ]; then
    mkdir -p `dirname $log`
  fi

  if [ "$format" == "short" ]; then
    if [ -z "$days" ]; then
      keep="4"
    else
      keep=$[$days - 1]
    fi
  fi

  if [ ! -z "$nicelevel" ]; then 
    nice="nice -n $nicelevel"
  else 
    nice=""
  fi

  ssh_cmd_base="ssh -T -o PasswordAuthentication=no -p $port -i $id_file"
  ssh_cmd="$ssh_cmd_base $user@$host bash"

  if [ "$from" == "remote" ] || [ "$dest" == "remote" ]; then
    if [ "$testconnect" == "yes" ] && [ "$protocol" == "ssh" ]; then
      test_connect $host $port $user $id_file
    fi
  fi

  if [ "$multiconnection" == "yes" ]; then
    ssh_cmd="$ssh_cmd -S $tmp/%r@%h:%p"
  fi

  if [ $enable_mv_timestamp_bug == "yes" ]; then
    mv=move_files
  fi

  set -o noglob
  SAVEIFS=$IFS
  IFS=$(echo -en "\n\b")
  for i in $exclude; do
     str="${i//__star__/*}"
     excludes="${excludes} --exclude='$str'"
  done
  IFS=$SAVEIFS
  set +o noglob
}

function rotate_short {

  local dest
  local folder="$1"
  local keep="$2"
  local metadata="`dirname $folder`/metadata"

  # No rotations
  if [[ "$keep" -lt 1 ]]; then
     return
  fi

  if [ -d $folder.$keep ]; then
    $nice $mv /$folder.$keep /$folder.tmp
  fi

  for ((n=$[$keep - 1]; n >= 0; n--)); do
    if [ -d $folder.$n ]; then
      dest=$[$n + 1]
      $nice $mv /$folder.$n /$folder.$dest
      $touch /$folder.$dest
      mkdir -p $metadata/`basename $folder`.$dest
      date +%c%n%s > $metadata/`basename $folder`.$dest/rotated
    fi
  done

  if [ -d $folder.tmp ]; then
    $nice $mv /$folder.tmp /$folder.0
  fi

  if [ -d $folder.1 ]; then
    $nice $cp -alf /$folder.1/. /$folder.0
  fi

  # Cleanup orphaned metadata
  for file in `ls $metadata`; do
    if [ ! -d "`dirname $folder`/$file" ]; then
      debug "removing orphaned metadata $file"
      rm -rf $metadata/$file
    fi
  done

}

function rotate_short_remote {

  local folder="$1"
  local metadata="`dirname $folder`/metadata"
  local keep="$2"

  # No rotations
  if [[ "$keep" -lt 1 ]]; then
     return
  fi

(
  $ssh_cmd <<EOF
  ##### BEGIN REMOTE SCRIPT #####

  if [ -d $folder.$keep ]; then
    $nice mv /$folder.$keep /$folder.tmp
  fi

  for ((n=$(($keep - 1)); n >= 0; n--)); do
    if [ -d $folder.\$n ]; then
      dest=\$((\$n + 1))
      $nice mv /$folder.\$n /$folder.\$dest
      touch /$folder.\$dest
      mkdir -p $metadata/`basename $folder`.\$dest
      date +%c%n%s > $metadata/`basename $folder`.\$dest/rotated
    fi
  done

  if [ -d $folder.tmp ]; then
    $nice mv /$folder.tmp /$folder.0
  fi

  if [ -d $folder.1 ]; then
    $nice $cp -alf /$folder.1/. /$folder.0
  fi

  # Cleanup orphaned metadata
  for file in \`ls $metadata\`; do
    if [ ! -d "`dirname $folder`/\$file" ]; then
      echo "Debug: removing orphaned metadata \$file"
      rm -rf $metadata/\$file
    fi
  done
  ##### END REMOTE SCRIPT #######
EOF
) | (while read a; do passthru $a; done)

}

function rotate_long {

  backuproot="$1"
  seconds_daily=86400
  seconds_weekly=604800
  seconds_monthly=2628000
  keepdaily=$keepdaily
  keepweekly=$keepweekly
  keepmonthly=$keepmonthly
  now=`date +%s`

  local metadata

  if [ ! -d "$backuproot" ]; then
    warning "Skipping rotate of $backuproot as it doesn't exist."
    return
  fi

  for rottype in daily weekly monthly; do
    seconds=$((seconds_${rottype}))
    dir="$backuproot/$rottype"
    metadata="$backuproot/metadata/$rottype"

    mkdir -p $metadata.1
    if [ ! -d $dir.1 ]; then
      echo "Debug: $dir.1 does not exist, skipping."
      continue 1
    elif [ ! -f $metadata.1/created ] && [ ! -f $metadata.1/rotated ]; then
      warning "Warning: metadata does not exist for $dir.1. This backup may be only partially completed. Skipping rotation."
      continue 1
    fi
    
    # Rotate the current list of backups, if we can.
    oldest=`find $backuproot -maxdepth 1 -type d -name $rottype'.*' | /bin/sed -e 's/^.*\.//' | sort -n | tail -1`
    [ "$oldest" == "" ] && oldest=0
    for (( i=$oldest; i > 0; i-- )); do
      if [ -d $dir.$i ]; then
        if [ -f $metadata.$i/created ]; then
          created=`tail -1 $metadata.$i/created`
        elif [ -f $metadata.$i/rotated ]; then
          created=`tail -1 $metadata.$i/rotated`
        else
          created=0
        fi
        # Validate created date
        if [ -z "$created" ] || echo $created | grep -v -q -e '^[0-9]*$'; then
           warning "Invalid metadata $created. Skipping rotation."
           break
        fi
        cutoff_time=$(( now - (seconds*(i-1)) ))
        if [ ! $created -gt $cutoff_time ]; then
          next=$(( i + 1 ))
          if [ ! -d $dir.$next ]; then
            debug "$rottype.$i --> $rottype.$next"
            $nice mv $dir.$i $dir.$next
            mkdir -p $metadata.$next
            date +%c%n%s > $metadata.$next/rotated
            if [ -f $metadata.$i/created ]; then
              $nice mv $metadata.$i/created $metadata.$next
            fi
          else
            debug "skipping rotation of $dir.$i because $dir.$next already exists."
          fi
        else
          debug "skipping rotation of $dir.$i because it was created" $(( (now-created)/86400)) "days ago ("$(( (now-cutoff_time)/86400))" needed)."
        fi
      fi
    done
  done

  max=$((keepdaily+1))
  if [ $keepweekly -gt 0 -a -d $backuproot/daily.$max -a ! -d $backuproot/weekly.1 ]; then
    debug "daily.$max --> weekly.1"
    $nice mv $backuproot/daily.$max $backuproot/weekly.1
    mkdir -p $backuproot/metadata/weekly.1
    date +%c%n%s > $backuproot/metadata/weekly.1/rotated
    #if [ -f $backuproot/metadata/daily.$max/created  ]; then
    #   $nice mv $backuproot/metadata/daily.$max/created $backuproot/metadata/weekly.1/
    #fi
  fi

  max=$((keepweekly+1))
  if [ $keepmonthly -gt 0 -a -d $backuproot/weekly.$max -a ! -d $backuproot/monthly.1 ]; then
    debug "weekly.$max --> monthly.1"
    $nice mv $backuproot/weekly.$max $backuproot/monthly.1
    mkdir -p $backuproot/metadata/monthly.1
    date +%c%n%s > $backuproot/metadata/monthly.1/rotated
    #if [ -f $backuproot/metadata/weekly.$max/created  ]; then
    #   $nice mv $backuproot/metadata/weekly.$max/created $backuproot/metadata/weekly.1/
    #fi
  fi

  for rottype in daily weekly monthly; do
    max=$((keep${rottype}+1))
    dir="$backuproot/$rottype"
    oldest=`find $backuproot -maxdepth 1 -type d -name $rottype'.*' | /bin/sed -e 's/^.*\.//' | sort -n | tail -1`
    [ "$oldest" == "" ] && oldest=0 
    # if we've rotated the last backup off the stack, remove it.
    for (( i=$oldest; i >= $max; i-- )); do
      if [ -d $dir.$i ]; then
        if [ -d $backuproot/rotate.tmp ]; then
          debug "removing rotate.tmp"
          $nice rm -rf $backuproot/rotate.tmp
        fi
        debug "moving $rottype.$i to rotate.tmp"
        $nice mv $dir.$i $backuproot/rotate.tmp
      fi
    done
  done

  # Cleanup orphaned metadata
  for file in `ls $backuproot/metadata`; do
    if [ ! -d "$backuproot/$file" ]; then
      debug "removing orphaned metadata $file"
      rm -rf $backuproot/metadata/$file
    fi
  done

}

function rotate_long_remote {

  local backuproot="$1"

(
  $ssh_cmd <<EOF
  ##### BEGIN REMOTE SCRIPT #####

  seconds_daily=86400
  seconds_weekly=604800
  seconds_monthly=2628000
  keepdaily=$keepdaily
  keepweekly=$keepweekly
  keepmonthly=$keepmonthly
  now=\`date +%s\`

  if [ ! -d "$backuproot" ]; then
    echo "Fatal: skipping rotate of $backuproot as it doesn't exist."
    exit
  fi

  for rottype in daily weekly monthly; do
    seconds=\$((seconds_\${rottype}))
    dir="$backuproot/\$rottype"
    metadata="$backuproot/metadata/\$rottype"

    mkdir -p \$metadata.1
    if [ ! -d \$dir.1 ]; then
      echo "Debug: \$dir.1 does not exist, skipping."
      continue 1
    elif [ ! -f \$metadata.1/created ] && [ ! -f \$metadata.1/rotated ]; then
      echo "Warning: metadata does not exist for \$dir.1. This backup may be only partially completed. Skipping rotation."
      continue 1
    fi
    
    # Rotate the current list of backups, if we can.
    oldest=\`find $backuproot -maxdepth 1 -type d -name \$rottype'.*' | /bin/sed -e 's/^.*\.//' | sort -n | tail -1\`
    [ "\$oldest" == "" ] && oldest=0
    for (( i=\$oldest; i > 0; i-- )); do
      if [ -d \$dir.\$i ]; then
        if [ -f \$metadata.\$i/created ]; then
          created=\`tail -1 \$metadata.\$i/created\`
        elif [ -f \$metadata.\$i/rotated ]; then
          created=\`tail -1 \$metadata.\$i/rotated\`
        else
          created=0
        fi
        # Validate created date
        if [ -z "\$created" ] || echo \$created | grep -v -q -e '^[0-9]*$'; then
           echo "Warning: Invalid metadata \$created. Skipping rotation."
           break
        fi
        cutoff_time=\$(( now - (seconds*(i-1)) ))
        if [ ! \$created -gt \$cutoff_time ]; then
          next=\$(( i + 1 ))
          if [ ! -d \$dir.\$next ]; then
            echo "Debug: \$rottype.\$i --> \$rottype.\$next"
            $nice mv \$dir.\$i \$dir.\$next
            mkdir -p \$metadata.\$next
            date +%c%n%s > \$metadata.\$next/rotated
            if [ -f \$metadata.\$i/created ]; then
              $nice mv \$metadata.\$i/created \$metadata.\$next
            fi
          else
            echo "Debug: skipping rotation of \$dir.\$i because \$dir.\$next already exists."
          fi
        else
          echo "Debug: skipping rotation of \$dir.\$i because it was created" \$(( (now-created)/86400)) "days ago ("\$(( (now-cutoff_time)/86400))" needed)."
        fi
      fi
    done
  done

  max=\$((keepdaily+1))
  if [ \$keepweekly -gt 0 -a -d $backuproot/daily.\$max -a ! -d $backuproot/weekly.1 ]; then
    echo "Debug: daily.\$max --> weekly.1"
    $nice mv $backuproot/daily.\$max $backuproot/weekly.1
    mkdir -p $backuproot/metadata/weekly.1
    date +%c%n%s > $backuproot/metadata/weekly.1/rotated
    #if [ -f $backuproot/metadata/daily.\$max/created  ]; then
    #   $nice mv $backuproot/metadata/daily.\$max/created $backuproot/metadata/weekly.1/
    #fi
  fi

  max=\$((keepweekly+1))
  if [ \$keepmonthly -gt 0 -a -d $backuproot/weekly.\$max -a ! -d $backuproot/monthly.1 ]; then
    echo "Debug: weekly.\$max --> monthly.1"
    $nice mv $backuproot/weekly.\$max $backuproot/monthly.1
    mkdir -p $backuproot/metadata/monthly.1
    date +%c%n%s > $backuproot/metadata/monthly.1/rotated
    #if [ -f $backuproot/metadata/weekly.\$max/created  ]; then
    #   $nice mv $backuproot/metadata/weekly.\$max/created $backuproot/metadata/weekly.1/
    #fi
  fi

  for rottype in daily weekly monthly; do
    max=\$((keep\${rottype}+1))
    dir="$backuproot/\$rottype"
    oldest=\`find $backuproot -maxdepth 1 -type d -name \$rottype'.*' | /bin/sed -e 's/^.*\.//' | sort -n | tail -1\`
    [ "\$oldest" == "" ] && oldest=0 
    # if we've rotated the last backup off the stack, remove it.
    for (( i=\$oldest; i >= \$max; i-- )); do
      if [ -d \$dir.\$i ]; then
        if [ -d $backuproot/rotate.tmp ]; then
          echo "Debug: removing rotate.tmp"
          $nice rm -rf $backuproot/rotate.tmp
        fi
        echo "Debug: moving \$rottype.\$i to rotate.tmp"
        $nice mv \$dir.\$i $backuproot/rotate.tmp
      fi
    done
  done

  # Cleanup orphaned metadata
  for file in \`ls $backuproot/metadata\`; do
    if [ ! -d "$backuproot/\$file" ]; then
      echo "Debug: removing orphaned metadata \$file"
      rm -rf $backuproot/metadata/\$file
    fi
  done
  ##### END REMOTE SCRIPT #######
EOF
) | (while read a; do passthru $a; done)

}

function setup_long_dirs {

  local destdir=$1
  local backuptype=$2
  local dir="$destdir/$backuptype"
  local tmpdir="$destdir/rotate.tmp"
  local metadata="$destdir/metadata/$backuptype.1"

  if [ ! -d $destdir ]; then
    echo "Creating destination directory $destdir..."
    mkdir -p $destdir
  fi

  if [ -d $dir.1 ]; then
    if [ -f $metadata/created ]; then
      echo "Warning: $dir.1 already exists. Overwriting contents."
    else
      echo "Warning: we seem to be resuming a partially written $dir.1"
    fi
  else
    if [ -d $tmpdir ]; then
      mv $tmpdir $dir.1
      if [ $? == 1 ]; then
        fatal "Could not move $tmpdir to $dir.1 on host $host"
      fi
    else
      mkdir --parents $dir.1
      if [ $? == 1 ]; then
        fatal "Could not create directory $dir.1 on host $host"
      fi
    fi
    if [ -d $dir.2 ]; then
      echo "Debug: update links $backuptype.2 --> $backuptype.1"
      cp -alf $dir.2/. $dir.1
      #if [ $? == 1 ]; then
      #  fatal "Could not create hard links to $dir.1 on host $host"
      #fi
    fi
  fi
  [ -f $metadata/created ] && rm $metadata/created
  [ -f $metadata/rotated ] && rm $metadata/rotated

}

function setup_long_dirs_remote {

  local destdir=$1
  local backuptype=$2
  local dir="$destdir/$backuptype"
  local tmpdir="$destdir/rotate.tmp"
  local metadata="$destdir/metadata/$backuptype.1"

(
  $ssh_cmd <<EOF
  ##### BEGIN REMOTE SCRIPT #####
  if [ ! -d $destdir ]; then
    echo "Creating destination directory $destdir on $host..."
    mkdir -p $destdir
  fi

  if [ -d $dir.1 ]; then
    if [ -f $metadata/created ]; then
      echo "Warning: $dir.1 already exists. Overwriting contents."
    else
      echo "Warning: we seem to be resuming a partially written $dir.1"
    fi
  else
    if [ -d $tmpdir ]; then
      mv $tmpdir $dir.1
      if [ \$? == 1 ]; then
        echo "Fatal: could mv $destdir/rotate.tmp $dir.1 on host $host"
        exit 1
      fi
    else
      mkdir --parents $dir.1
      if [ \$? == 1 ]; then
        echo "Fatal: could not create directory $dir.1 on host $host"
        exit 1
      fi
    fi
    if [ -d $dir.2 ]; then
      echo "Debug: update links $backuptype.2 --> $backuptype.1"
      cp -alf $dir.2/. $dir.1
      #if [ \$? == 1 ]; then
      #  echo "Fatal: could not create hard links to $dir.1 on host $host"
      #  exit 1
      #fi
    fi
  fi
  [ -f $metadata/created ] && rm $metadata/created
  [ -f $metadata/rotated ] && rm $metadata/rotated
  ##### END REMOTE SCRIPT #######
EOF
) | (while read a; do passthru $a; done)

}

function move_files {

  ref=$tmp/makesnapshot-mymv-$$;
  $touch -r $1 $ref;
  $mv $1 $2;
  $touch -r $ref $2;
  $rm $ref;

}

function prepare_storage {

  section="`basename $SECTION`"

  if [ "$format" == "short" ]; then

    suffix="$section.0"
    info "Rotating $backupdir/$SECTION..."
    echo "Rotating $backupdir/$SECTION..." >> $log

    if [ "$dest" == "remote" ]; then
      rotate_short_remote $backupdir/$SECTION/$section $keep
    else
      rotate_short $backupdir/$SECTION/$section $keep
      if [ ! -d "$backupdir/$SECTION/$section.0" ]; then
        mkdir -p $backupdir/$SECTION/$section.0
      fi
    fi

  elif [ "$format" == "long" ]; then

    if [ $keepdaily -gt 0 ]; then
      btype=daily
    elif [ $keepweekly -gt 0 ]; then
      btype=weekly
    elif [ $keepmonthly -gt 0 ]; then
      btype=monthly
    else
      fatal "keeping no backups";
    fi

    suffix="$btype.1"
    info "Rotating $backupdir/$SECTION/..."
    echo "Rotating $backupdir/$SECTION/..." >> $log

    if [ "$dest" == "remote" ]; then
      rotate_long_remote $backupdir/$SECTION
      setup_long_dirs_remote $backupdir/$SECTION $btype
    else
      rotate_long $backupdir/$SECTION
      setup_long_dirs $backupdir/$SECTION $btype
    fi

  elif [ "$format" == "mirror" ]; then
    suffix=""
  else
    fatal "Invalid backup format $format"
  fi

}

function set_orig {

  if [ "$from" == "local" ]; then
    orig="/$SECTION/"
  elif [ "$from" == "remote" ]; then
    if [ "$protocol" == "rsync" ]; then
      orig="rsync://$user@$host:$port/$SECTION/"
    else
      orig="$user@$host:/$SECTION/"
    fi
  fi

}

function set_dest { 

  if [ "$dest" == "local" ]; then
    dest_path="$backupdir/$SECTION/$suffix/"
  else
    if [ "$protocol" == "rsync" ]; then
      dest_path="rsync://$user@$host:$port/$backupdir/$SECTION/$suffix/"
    else
      dest_path="$user@$host:$backupdir/$SECTION/$suffix/"
    fi
  fi

}

function set_batch_mode {

  local batch_file="$batchbase/$SECTION/$suffix"

  if [ "$batch" == "read" ]; then
    if [ -e "$batch_file" ]; then
      orig=""
      excludes=""
      batch_option="--read-batch=$batch_file"
    else
      fatal "Batch file not found: $batch_file"
    fi
  elif [ "$batch" == "write" ]; then
    mkdir -p `dirname $batch_file`
    batch_option="--write-batch=$batch_file"
  fi

}

function update_metadata {

  local metadata
  local folder

  if [ "$dest" == "local" ]; then
    metadata="`dirname $dest_path`/metadata/`basename $dest_path`"
    mkdir -p $metadata
    # Use the backup start time and not the time the backup was
    # finished, otherwise daily rotations might not take place.
    # If we used backup end time, in the next handler run
    # we might not have $now - $created >= 24:00
    echo "$starttime" > $metadata/created
    $touch $backupdir/$SECTION/$suffix
  else
    folder="`echo $dest_path | cut -d : -f 2`"
    metadata="`dirname $folder`/metadata/`basename $folder`"

(
  $ssh_cmd <<EOF
    ##### BEGIN REMOTE SCRIPT #####
    mkdir -p $metadata
    # Use the backup start time and not the time the backup was
    # finished, otherwise daily rotations might not take place.
    # If we used backup end time, in the next handler run
    # we might not have $now - $created >= 24:00
    echo "$starttime" > $metadata/created
    ##### END REMOTE SCRIPT #######
EOF
) | (while read a; do passthru $a; done)

  fi

}

function test_connect {

  local host="$1"
  local port="$2"
  local user="$3"
  local id_file="$4"

  if [ -z "$host" ] || [ -z "$user" ]; then
    fatal "Remote host or user not set"
  fi

  debug "$ssh_cmd 'echo -n 1'"
  result=`$ssh_cmd 'echo -n 1'`

  if [ "$result" != "1" ]; then
    fatal "Can't connect to $host as $user."
  else
    debug "Connected to $host successfully"
  fi

}

function set_filelist {

  filelist_flag=""

  if [ "$filelist" == "yes" ]; then
    if [ ! -z "$filelistbase" ]; then
      if [ -e "$filelistbase/$SECTION/$suffix" ]; then
        filelist_flag="--files-from=$filelistbase/$SECTION/$suffix"
      else
        warning "File list $filelistbase/$SECTION/$suffix not found."
      fi
    else
      warning "No filelistbase set."
    fi
  fi

}

function set_rsync_options {

  if [ "$numericids" != "0" ]; then
    rsync_options="$rsync_options --numeric-ids"
  fi

  if [ "$from" == "local" ] || [ "$dest" == "local" ]; then
    # rsync options for local sources or destinations
    true
  fi

  if [ "$from" == "remote" ] || [ "$dest" == "remote" ]; then

    # rsync options for remote sources or destinations

    if [ "$compress" == "1" ]; then
      rsync_options="$rsync_options --compress"
    fi

    if [ ! -z "$bandwidthlimit" ]; then
      rsync_options="$rsync_options --bwlimit=$bandwidthlimit"
    fi
    
    if [ "$fakesuper" == "yes" ]; then
      remote_rsync="$remote_rsync --fake-super"
    fi

    if [ "$protocol" == "ssh" ]; then
      if [ ! -e "$id_file" ]; then
        fatal "SSH Identity file $id_file not found"
      else
        debug RSYNC_RSH=\"$ssh_cmd_base\"
        echo RSYNC_RSH=\"$ssh_cmd_base\" >> $log
        export RSYNC_RSH="$ssh_cmd_base"
      fi
    fi

  fi

  # Mangle rsync_options so we can use quotes after all other
  # options were evaluated.
  if [ "$from" == "local" ] && [ "$dest" == "local" ]; then
    rsync_options=($rsync_options)
  else
    rsync_options=($rsync_options --rsync-path="$remote_rsync")
  fi

  include_vservers

}

function stop_services {

  if [ ! -z "$service" ]; then
    for daemon in $service; do
      info "Stopping service $daemon..."
      $initscripts/$daemon stop
    done
  fi

}

function start_services {

  # restart services

  if [ ! -z "$service" ]; then
    for daemon in $service; do
      info "Starting service $daemon..."
      $initscripts/$daemon start
    done
  fi

}

function mount_rw {

  # mount backup destination folder as read-write

  if [ "$dest" == "local" ]; then
    if [ "$read_only" == "1" ] || [ "$read_only" == "yes" ]; then
      if [ -d "$mountpoint" ]; then
        mount -o remount,rw $mountpoint
        if (($?)); then
          fatal "Could not mount $mountpoint"
        fi
      fi
    fi
  fi

}

function mount_ro {

  # remount backup destination as read-only

  if [ "$dest" == "local" ]; then
    if [ "$read_only" == "1" ] || [ "$read_only" == "yes" ]; then
      mount -o remount,ro $mountpoint
    fi
  fi

}

function run_fsck {

  # check partition for errors

  if [ "$dest" == "local" ]; then
    if [ "$fscheck" == "1" ] || [ "$fscheck" == "yes" ]; then
      umount $mountpoint
      if (($?)); then
        warning "Could not umount $mountpoint to run fsck"
      else
        $nice $fsck -v -y $partition >> $log
        mount $mountpoint
      fi
    fi
  fi

}

function include_vservers {

  # add vservers to included folders

  if [ "$vservers_are_available" == "yes" ]; then

    # sane permission on backup
    mkdir -p $backupdir/$VROOTDIR
    chmod 000 $backupdir/$VROOTDIR

    for candidate in $found_vservers; do
      candidate="`basename $candidate`"
      found_excluded_vserver="0"
      for excluded_vserver in $exclude_vserver; do
        if [ "$excluded_vserver" == "$candidate" ]; then
          found_excluded_vserver="1"
          break
        fi
      done
      if [ "$found_excluded_vserver" == "0" ]; then
        include="$include $VROOTDIR/$candidate"
      fi
    done
  fi

}

function start_mux {

  if [ "$multiconnection" == "yes" ]; then
    debug "Starting master ssh connection"
    $ssh_cmd -M sleep 1d &
    sleep 1
  fi

}

function end_mux {

  if [ "$multiconnection" == "yes" ]; then
    debug "Stopping master ssh connection"
    $ssh_cmd pkill sleep
  fi

}

function set_pipefail {

  # Save initial pipefail status for later restoration
  if echo "$SHELLOPTS" | grep -q ":pipefail"; then
     pipefail="-o"
  else
     pipefail="+o"
  fi

  # Ensure that a non-zero rsync exit status is caught by our handler
  set -o pipefail

}

function restore_pipefail {

  if [ ! -z "$pipefail" ]; then
    set $pipefail pipefail
  fi

}

function check_rsync_exit_status {

  if [ -z "$1" ]; then
    return
  fi

  case $1 in
    0)
       return
       ;;
    1|2|3|4|5|6|10|11|12|13|14|21)
       fatal "Rsync error $1 when trying to transfer $SECTION"
       ;;
    *)
       warning "Rsync error $1 when trying to transfer $SECTION"
       ;;
  esac

}

# the backup procedure

eval_config
set_rsync_options
start_mux
stop_services
mount_rw

starttime="`date +%c%n%s`"
echo "Starting backup at `echo "$starttime" | head -n 1`" >> $log

for SECTION in $include; do

  prepare_storage
  set_orig
  set_batch_mode
  set_filelist
  set_dest

  info "Syncing $SECTION on $dest_path..."
  debug $nice $rsync ${rsync_options[*]} $filelist_flag $excludes $batch_option $orig $dest_path
  set_pipefail
  $nice su -c "$rsync ${rsync_options[*]} --delete-excluded $filelist_flag $excludes $batch_option $orig $dest_path" | tee -a $log

  check_rsync_exit_status $?
  restore_pipefail
  update_metadata

done

mount_ro
run_fsck
start_services
end_mux

echo "Finnishing backup at `date`" >> $log
