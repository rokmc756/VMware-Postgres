## What is vmware-postgres ansible playbook?
It is ansible playbook to deploy VMware Postgres conveniently on Baremetal, Virtual Machines and Cloud Infrastructure.
It provide also pgwatch2 and grafana for monitoring features as well as SSL connection automatically when deploying it.
The main purpose of this project is actually very simple. Because there are many jobs to install different kind of VMware Postgres versions and reproduce issues & test features as a support
engineer. I just want to spend less time for it.

If you are working with VMware Postgrs such as Developer, Administrator, Field Engineer or Database Administrator you could also utilize it very conviently as saving time.
## Where is this ansible playbook from and how is it changed?

It's originated by itself.
## Supported VMware Postgres versions
* Pivotal Postgres 10.x, 11.x
* VMware Postgres 10.x, 11.x, 12.x, 13,x, 14.x, 15.x
## Supported Platform and OS
* Virtual Machines
* Baremetal
* RHEL/CentOS/Rocky Linux 7.x, 8.x, 9.x
## Prerequisite
* acOS or Fedora/CentOS/RHEL should have installed ansible as ansible host.
* Supported OS for ansible target host should be prepared with package repository configured such as yum, dnf and apt
## Prepare ansible host to run vmware-postgres ansible playbook
* MacOS
```
$ xcode-select --install
$ brew install ansible
$ brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb
```
* Fedora/CentOS/RHEL
```
$ sudo yum install ansible
```
## Prepareing OS
* Configure Yum / Local & EPEL Repostiory
## Download / configure / run VMware Postgres
```
$ git clone https://github.com/rokmc756/VMware-Postgres
$ cd VMware-Postgres
$ vi Makefile
~~ snip
ANSIBLE_HOST_PASS="changeme"    # It should be changed with password of user in ansible host that vmware-postgres would be run.
ANSIBLE_TARGET_PASS="changeme"  # It should be changed with password of sudo user in managed nodes that vmware-postgres would be installed.
~~ snip
```
## For Single VMware Postgres
#### 1) The Architecure of Single VMware Postgres with pgwatch2 and grafana
![alt text](https://github.com/rokmc756/vmware-postgres/blob/main/roles/pgwatch2/images/pgwatch2_architecture.png)
#### 2) Configure inventory for Single VMware Postgres
```
$ vi ansible-hosts-rh9-single
[all:vars]
ssh_key_filename="id_rsa"
remote_machine_username="jomoon"              # Replace with sudo user of vmware-postgres administrator
remote_machine_password="changeme"            # Replace with password of sudo user

[monitors]
rh9-master ansible_ssh_host=192.168.0.191

[slave]
rh9-slave  ansible_ssh_host=192.168.0.192

[workers]
rh9-node01 ansible_ssh_host=192.168.0.193
rh9-node02 ansible_ssh_host=192.168.0.194
rh9-node03 ansible_ssh_host=192.168.0.195
```
#### 3) Configure variables for Single VMware Postgres
```
$ vi roles/single/vars/main.yml
major_version: 15
minor_version: 5
patch_version: 1
rhel_version: el9
# package_name: "vmware-postgres"                        # In case of version within 12
# package_name: "pivotal-postgres"                       # In case of version within 11
# bin_dir: "/usr/bin"
package_name: "vmware-postgres{{ major_version }}"       # In case of version higher than 13
bin_dir: "/opt/vmware/postgres/{{ major_version }}/bin"  # In case of version higher than 13
database_name: testdb
username: jomoon
password: changeme
user: postgres
group: postgres
sslmode: prefer
app_database: testdb
~~ snip
```
#### 4) Deploy Single VMware Postgres
```
$ vi install-hosts.yml
- hosts: all
  become: yes
  vars:
    print_debug: true
    install_pkgs: true
    install_dep_pkgs: true
    install_go: true
    install_prometheus: true
    install_grafana: true
    install_pgwatch2: true
  roles:
    - { role: init-hosts }
    - { role: single }
#    - { role: grafana }
#    - { role: pgwatch2 }

$ make install
```
#### 5) Destroy Single VMware-Postgres
```
$ vi uninstall-hosts.yml
- hosts: all
  become: yes
  vars:
    print_debug: true
    uninstall_pkgs: true
    uninstall_dep_pkgs: true
    uninstall_go: true
    uninstall_prometheus: true
    uninstall_grafana: true
    uninstall_pgwatch2: true
  roles:
    - { role: single }
    - { role: init-hosts }
#    - { role: grafana }
#    - { role: pgwatch2 }

$ make uninstall
```
## For Patroni Cluster
#### 1) The Architecture of Patroni Cluster
![alt text](https://github.com/rokmc756/vmware-postgres/blob/main/roles/patroni/images/patroni_architecture.jpeg)
#### 2) Configure inventory for Patroni Cluster
$ vi ansible-hosts-rh9-patroni
```
[all:vars]
ssh_key_filename="id_rsa"
remote_machine_username="jomoon"              # Replace with sudo user of vmware-postgres administrator
remote_machine_password="changeme"            # Replace with password of sudo user

[workers]
rk9-node01 ansible_ssh_host=192.168.2.191
rk9-node02 ansible_ssh_host=192.168.2.192
rk9-node03 ansible_ssh_host=192.168.2.193
rk9-node04 ansible_ssh_host=192.168.2.194
rk9-node05 ansible_ssh_host=192.168.2.195
```

#### 3) Configure variables for Patroni Cluster
```
$ vi roles/patroni/vars/main.yml
---
_ssl:
  ssl_dir: "{{ pgsql.base_dir }}/certs"
  ssl_days: 3660
  ssl_country: "KR"
  ssl_state: "Seoul"
  ssl_location: "Guro"
  ssl_organization: "VMware"
  ssl_organization_unit: "Tanzu"
  ssl_common_name: "jtest.pivotal.io"
  ssl_email: "jomoon@pivotal.io"

_patroni:
  major_version: "3"
  minor_version: "2"
  patch_version: "0"
  build_version: "1"
  os_version: el9
  arch_type: x86_64
  bin_type: rpm
  bin_path: "{{ common.pgsql_bin_dir }}/patroni"
  ctl_path: "{{ common.pgsql_bin_dir }}/patronictl"
  cluster_name: patclu01
  sync_mode: True
  with_pkgs: True
  enable_ssl: False
  # false is for pgbackrest, not found yet how does pgbackrest
  # interactive with synchronous mode in patroni cluster
  # sync_mode: on    # one of node will be a Sync Standby role

_etcd:
  major_version: "3"
  minor_version: "3"
  patch_version: "27"
  build_version: ""
  arch_type: x86_64
  os_version: el9
  bin_type: rpm
  download_bin: false
  blank: " "
~~ snip
```
#### 4) Deploy Patroni Cluster
```
$ make hosts r=init

or
$ make patroni r=config s=firewall
$ make patroni r=install s=pkgs
$ make patroni r=install s=etcd
$ make patroni r=config s=env
$ make patroni r=enable s=ssl
$ make patroni r=install s=patroni
$ make patroni r=add s=user

or
$ make patroni r=install s=all

```
#### 5) Destroy Patroni Cluster
```
$ make patroni r=stop s=service
$ make patroni r=uninstall s=pkgs
$ make patroni r=remove s=env
$ make patroni r=disable s=firewall

or
$ make patroni r=uninstall s=all
```
## For PGAutoFailover Cluster
#### 1) The Architecture
![alt text](https://github.com/rokmc756/vmware-postgres/blob/main/roles/pgautofailover/images/pgautofailover_architecture.svg)
#### 2) Configure inventory for PGAutoFailover Cluster
```
$ vi ansible-hosts
[all:vars]
ssh_key_filename="id_rsa"
remote_machine_username="jomoon"              # Replace with sudo user of vmware-postgres administrator
remote_machine_password="changeme"            # Replace with password of sudo user

[monitors]
rh9-master ansible_ssh_host=192.168.0.191

[slave]
rh9-slave  ansible_ssh_host=192.168.0.192

[workers]
rh9-node01 ansible_ssh_host=192.168.0.193
rh9-node02 ansible_ssh_host=192.168.0.194
rh9-node03 ansible_ssh_host=192.168.0.195
```
#### 3) Deploy PGAutoFailover Cluster
```
$ vi install-hosts.yml
---
- hosts: all
  become: yes
  vars:
    print_debug: true
    install_dep_pkgs: true
    remove_dep_pkgs: true
    enable_ssl_monitor: true
  roles:
    - init-hosts
    - pgautofailover

$ make install
```
#### 4) Destroy PGAutoFailover Cluster
```
$ vi uninstall-hosts
---
- hosts: all
  become: yes
  vars:
    print_debug: true
    remove_dep_pkgs: true
  roles:
    - pgautofailover
    - init-hosts

$ make uninstall
```
## Planning
* Change centos and rockylinux mirror into local mirrors in Korea
* Add monitoring features with pgwatch2 and grafana for Single Postgres, PGAutofailover and Patroni Cluster
* Add additional extensions inlcuded in vmware-postgres zip file
* Add falut talerence feature with Keepalived for PGAutofailover and Patroni Cluster
* Add load balance feature with HAProxy for PGAutofailover and Patroni Cluster
