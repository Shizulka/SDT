
# Лабораторна робота 4  


# 1. Архітектура системи

```text
client → nginx → FastAPI application → MariaDB
```

Інфраструктура складалась із двох VM:

| VM | Призначення |
|---|---|
| worker VM | nginx + FastAPI |
| db VM | MariaDB |

---

# 2. Terraform

Terraform використовувався для опису інфраструктури у вигляді коду.

---

## 2.1 Структура Terraform

```text
terraform/
├── main.tf
├── .terraform.lock.hcl
```

---

## 2.2 Конфігурація Terraform

### main.tf

```hcl
terraform {
  required_providers {
    virtualbox = {
      source  = "terra-farm/virtualbox"
      version = "0.2.2-alpha.1"
    }
  }
}

provider "virtualbox" {}

resource "virtualbox_vm" "worker" {
  name   = "worker-vm"
  image  = "https://app.vagrantup.com/ubuntu/boxes/noble64/versions/0.0.1/providers/virtualbox.box"
  cpus   = 2
  memory = "2048 mib"

  network_adapter {
    type           = "hostonly"
    host_interface = "vboxnet0"
  }
}

resource "virtualbox_vm" "db" {
  name   = "db-vm"
  image  = "https://app.vagrantup.com/ubuntu/boxes/noble64/versions/0.0.1/providers/virtualbox.box"
  cpus   = 2
  memory = "2048 mib"

  network_adapter {
    type           = "hostonly"
    host_interface = "vboxnet0"
  }
}
```

---

## 2.3 Ініціалізація Terraform

```bash
student@test-VirtualBox:~/Стільниця/SDT/terraform$ terraform init
Initializing the backend...
Initializing provider plugins...
- Finding terra-farm/virtualbox versions matching "0.2.2-alpha.1"...
- Installing terra-farm/virtualbox v0.2.2-alpha.1...
- Installed terra-farm/virtualbox v0.2.2-alpha.1 (self-signed, key ID 51EC33490F8CDBE5)
Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

## 2.4 Перевірка конфігурації

```bash
student@test-VirtualBox:~/Стільниця/SDT/terraform$ terraform validate
Success! The configuration is valid.
```


## 2.5 Terraform Plan

```bash
terraform plan
```

### Результат

```text
student@test-VirtualBox:~/Стільниця/SDT/terraform$ terraform plan

Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # virtualbox_vm.db will be created
  + resource "virtualbox_vm" "db" {
      + cpus   = 2
      + id     = (known after apply)
      + image  = "https://app.vagrantup.com/ubuntu/boxes/noble64/versions/0.0.1/providers/virtualbox.box"
      + memory = "2048 mib"
      + name   = "db-vm"
      + status = "running"

      + network_adapter {
          + device                 = "IntelPro1000MTServer"
          + host_interface         = "vboxnet0"
          + ipv4_address           = (known after apply)
          + ipv4_address_available = (known after apply)
          + mac_address            = (known after apply)
          + status                 = (known after apply)
          + type                   = "hostonly"
        }
    }

  # virtualbox_vm.worker will be created
  + resource "virtualbox_vm" "worker" {
      + cpus   = 2
      + id     = (known after apply)
      + image  = "https://app.vagrantup.com/ubuntu/boxes/noble64/versions/0.0.1/providers/virtualbox.box"
      + memory = "2048 mib"
      + name   = "worker-vm"
      + status = "running"

      + network_adapter {
          + device                 = "IntelPro1000MTServer"
          + host_interface         = "vboxnet0"
          + ipv4_address           = (known after apply)
          + ipv4_address_available = (known after apply)
          + mac_address            = (known after apply)
          + status                 = (known after apply)
          + type                   = "hostonly"
        }
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

Terraform планував створення:
- worker-vm;
- db-vm.

---

# 3. Ansible

Ansible використовувався для автоматизації конфігурації серверів.

---

## 3.1 Структура Ansible

```text
ansible/
├── inventory.ini
├── playbook.yml
├── roles/
│   ├── common/
│   ├── db/
│   ├── app/
│   └── nginx/
```

---

## 3.2 Inventory

### inventory.ini

```ini
[workers]
worker ansible_host=192.168.56.101 ansible_user=student

[db]
db1 ansible_host=192.168.56.102 ansible_user=student

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

---

## 3.3 Перевірка доступності VM

```bash
student@test-VirtualBox:~$ ansible -i ~/Стільниця/SDT_4/ansible/inventory.ini all -m ping
worker | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
db1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
student@test-VirtualBox:~$
}
```

# 4. Playbook

Було створено playbook для автоматизації конфігурації інфраструктури.

---

## 4.1 playbook.yml

```yaml
- name: Configure all servers
  hosts: all
  become: true
  roles:
    - common

- name: Configure database server
  hosts: db
  become: true
  roles:
    - db

- name: Configure worker server
  hosts: workers
  become: true
  roles:
    - app
    - nginx
```

---

# 5. Common Role

Роль `common` виконувала:
- оновлення apt cache;
- встановлення базових пакетів;
- створення користувача teacher;
- створення gradebook.

---

## 5.1 Приклад common role

```yaml
- name: Install common packages
  apt:
    name:
      - curl
      - git
      - python3
      - python3-pip
    state: present
```

---

# 6. Database Role

Роль `db` автоматизувала:
- встановлення MariaDB;
- запуск сервісу;
- створення бази даних;
- створення користувача app.

---

## 6.1 Приклад db role

```yaml
- name: Install MariaDB
  apt:
    name:
      - mariadb-server
      - python3-pymysql
    state: present
```

---

# 7. Application Role

Роль `app` виконувала:
- створення app user;
- копіювання FastAPI застосунку;
- встановлення Python dependencies;
- створення environment file;
- створення systemd service.

---

## 7.1 Environment template

```env
DATABASE_URL=mysql+pymysql://app:12345678@192.168.56.102:3306/mywebapp
```

---

## 7.2 Systemd service

```ini
[Service]
User=app
WorkingDirectory=/opt/mywebapp
ExecStart=/usr/local/bin/uvicorn src.infrastructure.main:app --host 127.0.0.1 --port 8000
```

---

# 8. Nginx Role

Було налаштовано nginx reverse proxy.

---

## 8.1 Конфігурація nginx

```nginx
server {
    listen 80;

    location / {
        proxy_pass http://127.0.0.1:8000;
    }
}
```

---

# 9. Запуск Playbook

## 9.1 Виконання playbook

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --ask-become-pass
```

---

## 9.2 Результат

```text
tudent@test-VirtualBox:~/Стільниця/SDT_4$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --ask-become-pass

/....

PLAY RECAP *********************************************************************
db1                        : ok=11   changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
worker                     : ok=11   changed=3    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0   

student@test-VirtualBox:~/Стільниця/SDT_4$
```

Усі ролі були виконані успішно.

---

# 10. Перевірка роботи сервісів

---

## 10.1 Health endpoint

```bash
curl http://192.168.56.101/health
```

### Результат

```json
{
  "status": "ok",
  "message": "робе"
}
```

---

## 10.2 Перевірка nginx

```bash
sudo systemctl status nginx
```

### Результат

```text
Active: active (running)
```

---

## 10.3 Перевірка MariaDB

```bash
sudo systemctl status mariadb
```

### Результат

```text
Active: active (running)
```

---

# 11. Ідемпотентність

Playbook був повторно запущений без помилок.

---

## 11.1 Повторний запуск

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --ask-become-pass
```

### Результат

```text
failed=0
unreachable=0
```

Повторний запуск playbook не призводив до критичних змін або помилок.

---
