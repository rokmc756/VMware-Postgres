## What is vmware-postgres ansible playbook?
~~~
It is ansible playbook to deploy VMware Postgres conveniently on Baremetal, Virtual Machines and Cloud Infrastructure.
It provide also pgwatch2 and grafana for monitoring features as well as SSL connection automatically when deploying it.
The main purpose of this project is actually very simple. Because there are many jobs to install different kind of VMware Postgres versions and reproduce issues & test features as a support
engineer. I just want to spend less time for it.

If you are working with VMware Postgrs such as Developer, Administrator, Field Engineer or Database Administrator you could also utilize it very conviently as saving time.
~~~
## Where is this ansible playbook from and how is it changed?
~~~
It's originated by itself.
~~~
## Supported VMware Postgres versions
~~~
Pivotal Postgres 10.x, 11.x
VMware Postgres 10.x, 11.x, 12.x, 13,x, 14.x, 15.x
~~~
## Supported Platform and OS
~~~
Virtual Machines
Baremetal
RHEL/CentOS/Rocky Linux 7.x, 8.x, 9.x
~~~
## Prerequisite
~~~
MacOS or Fedora/CentOS/RHEL should have installed ansible as ansible host.
Supported OS for ansible target host should be prepared with package repository configured such as yum, dnf and apt
~~~
## Prepare ansible host to run gpfarmer
* MacOS
~~~
$ xcode-select --install
$ brew install ansible
$ brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb
~~~
* Fedora/CentOS/RHEL
~~~
$ sudo yum install ansible
~~~
## Prepareing OS
* Configure Yum / Local & EPEL Repostiory
## Download / configure / run VMware Postgres
~~~
$ git clone https://github.com/rokmc756/vmware-postgres
$ cd vmware-postgres
$ vi Makefile
~~ snip
ANSIBLE_HOST_PASS="changeme"    # It should be changed with password of user in ansible host that vmware-postgres would be run.
ANSIBLE_TARGET_PASS="changeme"  # It should be changed with password of sudo user in managed nodes that vmware-postgres would be installed.
~~ snip
~~~
## For Single VMware Postgres
#### Configure inventory for Single VMware Postgres
~~~
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
~~~
#### Configure variables for Single VMware Postgres
~~~
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
~~~
#### Deploy Single VMware Postgres
~~~
$ vi install-hosts.yml
---
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
~~~
#### Destroy Single VMware-Postgres
~~~
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
~~~
## For Patroni Cluster
#### Configure inventory for Patroni Cluster
$ vi ansible-hosts-rh9-patroni
~~~
[all:vars]
ssh_key_filename="id_rsa"
remote_machine_username="jomoon"              # Replace with sudo user of vmware-postgres administrator
remote_machine_password="changeme"            # Replace with password of sudo user

[master]
rh9-master ansible_ssh_host=192.168.0.191

[slave]
rh9-slave  ansible_ssh_host=192.168.0.192

[workers]
rh9-node01 ansible_ssh_host=192.168.0.193
rh9-node02 ansible_ssh_host=192.168.0.194
rh9-node03 ansible_ssh_host=192.168.0.195
~~~

#### Configure variables for Patroni Cluster
~~~
$ vi roles/patroni/vars/main.yml
major_version: 15
minor_version: 5
build_version: 1
patch_version: 1
rhel_version: el9
patroni_version: "3.2.0-1"

# etcd 3.4.x and 3.5.x does not work for vmware-postgres 15.x versions
etcd_major_version: 3
etcd_minor_version: 3
etcd_build_version: 27
etcd_patch_version: 2

# etcd_minor_version: 3
# etcd_patch_version: 1
download_etcd_bin: false
~~ snip
~~~
#### Deploy Patroni Cluster
~~~
$ vi install-hosts.yml
---
- hosts: all
  gather_facts: true
  become: yes
  roles:
    - init-hosts

#
- hosts: workers
  gather_facts: true
  become: yes
  vars:
    print_debug: true
    config_firewall: true
    install_dep_pkgs: true    # ok
    install_pkgs: true
    install_pip_module: true   # ok
    config_env: true
    enable_ssl: true
    config_patroni: true
    add_users: true
  roles:
    - patroni

$ make install
~~~
#### Destroy Patroni Cluster
~~~
$ vi uninstall-hosts.yml
---
- hosts: workers
  gather_facts: true
  become: yes
  vars:
    print_debug: true
    remove_users: true
    disable_ssl: true
    remove_patroni_config: true
    remove_env_config: true
    uninstall_pkgs: true
    uninstall_pip_module: true
    uninstall_dep_pkgs: true
    remove_firewall_config: true
  roles:
    - patroni

#
- hosts: all
  gather_facts: true
  become: yes
  roles:
    - init-hosts

$ make uninstall
~~~
## For PGAutoFailover Cluster
#### Configure inventory for PGAutoFailover Cluster
~~~
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
~~~
#### Deploy PGAutoFailover Cluster
~~~
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
~~~
#### Destroy PGAutoFailover Cluster
~~~
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
~~~
## Planning
* Add monitoring features with pgwatch2 and grafana for Single Postgres, PGAutofailover and Patroni Cluster
* Add additional extensions inlcuded in vmware-postgres zip file
* Add falut talerence feature with Keepalived for PGAutofailover and Patroni Cluster
* Add load balance feature with HAProxy for PGAutofailover and Patroni Cluster
