backupninja:
  client:
    enabled: true
    auto_backup_disabled: true
    target:
      engine: dup
      url: s3+http://bucket-name/folder-name
      auth:
        awsaccesskeyid: awsaccesskeyid
        awssecretaccesskey: awssecretaccesskey