# Лабораторна робота №4

## Terraform + Ansible Infrastructure Automation

## Мета роботи

Метою лабораторної роботи було створення автоматизованої інфраструктури за допомогою Terraform та Ansible, налаштування віртуальних машин, автоматичне конфігурування сервісів, створення web application та reverse proxy.

---

# Хід виконання роботи

## 1. Налаштування Terraform та Libvirt

Для виконання лабораторної роботи було використано:

* Terraform
* Libvirt/KVM
* Cloud-init
* Ansible
* Ubuntu 22.04 cloud image

Було створено дві віртуальні машини:

* worker-vm
* db-vm

Terraform конфігурація створює:

* NAT network
* qcow2 диски
* cloud-init ISO
* VM domains
* автоматичне отримання IP

### main.tf

```hcl
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}
```

Було створено окрему мережу:

```hcl
resource "libvirt_network" "lab4_network" {
  name      = "lab4-network"
  mode      = "nat"
  domain    = "lab4.local"
  addresses = ["192.168.100.0/24"]

  dhcp {
    enabled = true
  }
}
```

Для cloud-init використовувався окремий файл `cloud-init.yml`.

---

## 2. Cloud-init конфігурація

Cloud-init автоматично:

* створює користувачів
* вмикає SSH
* встановлює Python
* створює gradebook
* налаштовує root filesystem

### cloud-init.yml

```yaml
#cloud-config

hostname: ${hostname}
manage_etc_hosts: true

ssh_pwauth: true

users:
  - default

  - name: ansible
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    plain_text_passwd: "12345678"
```

Було додано:

```yaml
growpart:
  mode: auto
  devices: ['/']

resize_rootfs: true
```

---

## 3. Виправлення проблем з Libvirt

Під час виконання роботи виникали проблеми:

### Permission denied для qcow2

Помилка:

```text
Could not open '/var/lib/libvirt/images/worker-vm.qcow2': Permission denied
```

Для вирішення було змінено налаштування libvirt:

```conf
user = "root"
group = "root"
security_driver = "none"
```

Файл:

```text
/etc/libvirt/qemu.conf
```

Після цього було виконано:

```bash
sudo systemctl restart libvirtd
```

---

## 4. Успішний Terraform apply

Після виправлення конфігурації Terraform успішно створив інфраструктуру.

### Успішний результат

```text
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

db_ip = "192.168.100.38"
worker_ip = "192.168.100.140"
```

Було створено:

* db-vm
* worker-vm
* lab4-network
* cloud-init диски
* qcow2 диски

---

# 5. Налаштування Ansible

Для конфігурації серверів використовувався Ansible.Після Terraform apply показуються айпі vm які треба вставити в inventory.ini.

## inventory.ini

```ini
[workers]
192.168.100.140 ansible_user=ansible ansible_password=12345678

[db]
192.168.100.38 ansible_user=ansible ansible_password=12345678

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

---

## 6. Перевірка доступності серверів

Було виконано:

```bash
ansible -i inventory.ini all -m ping
```

Успішний результат:

```text
192.168.100.140 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}

192.168.100.38 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

---

# 7. Налаштування ролей

Було створено ролі:

* common
* db
* app
* nginx

## common role

Виконує:

* apt update
* створення користувача teacher
* створення gradebook

## db role

Виконує:

* встановлення MariaDB
* створення БД
* створення користувача БД

## app role

Виконує:

* створення користувача app
* створення systemd service
* створення web application
* створення operator user
* sudo permissions

## nginx role

Виконує:

* встановлення nginx
* reverse proxy конфігурацію
* запуск nginx


# 8. Перевірка health endpoints

Було виконано:

```bash
curl http://192.168.100.140/health
curl http://192.168.100.140/alive
```

Результат:

```text
{"status":"ok","message":"робе"}
{"message":"робе"}
```

---

# 10. Успішний запуск playbook

Фінальний запуск:

```bash
ansible-playbook -i inventory.ini playbook.yml
```

Результат:

```text
PLAY RECAP

192.168.100.140 : ok=19 changed=11 unreachable=0 failed=0
192.168.100.38  : ok=10 changed=2  unreachable=0 failed=0
```

Повторний запуск:

```text
192.168.100.140 : ok=19 changed=5 unreachable=0 failed=0
192.168.100.38  : ok=10 changed=2 unreachable=0 failed=0
```

---



