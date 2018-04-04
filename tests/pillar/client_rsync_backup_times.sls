backupninja:
  client:
    enabled: true
    backup_times:
      day_of_week: 1
      hour: 4
      minute: 52
    target:
      engine: rsync
      host: 10.10.10.208
      user: backupninja
linux:
  system:
    name: hostname
    domain: domain