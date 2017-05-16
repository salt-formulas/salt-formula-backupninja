backupninja:
  client:
    enabled: true
    target:
      engine: dup
      url: webdavs://backup.cloud.example.com/box.example.com/
      auth:
        gss:
          principal: host/${linux:network:fqdn}
          keytab: /etc/krb5.keytab