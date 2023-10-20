#!/bin/bash

# HOSTS="81 82 83 84 85"
# HOSTS="171 172 173 174 175"
HOSTS="61 62 63 64 65"

for i in `echo $HOSTS`
do
    ssh root@192.168.0.$i "rm -rf /home/postgres/.local /home/postgres/.config ; /home/postgres/monitor /home/postgres/ha /home/postgres/appdb /home/postgres;  ls -al /home/postgres"
    ssh root@192.168.0.$i "systemctl stop pgautofailover"
    ssh root@192.168.0.$i "yum remove python3 python3-libs -y"
    ssh root@192.168.0.$i "yum remove vmware-postgres15 vmware-postgres14 vmware-postgres13 vmware-postgres postgresql postgresql-libs -y"
    ssh root@192.168.0.$i "killall postgres;"
    ssh root@192.168.0.$i "killall pg_autoctl;"
    ssh root@192.168.0.$i "rm -rf /home/postgres/.local ; rm -rf /var/lib/pgsql/* ; rm -rf /var/lib/pgsql/.local /var/lib/pgsql/.config ; rm -rf /tmp/pg_autoctl /var/lib/pgsql/backup /var/lib/pgsql/backups /var/lib/pgsql/.bash_profile; ls -al /var/lib/pgsql"
    ssh root@192.168.0.$i "userdel -r postgres"
    ssh root@192.168.0.$i "rm -rf /home/postgres"
done
