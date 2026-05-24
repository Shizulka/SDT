# Звіт з лабораторної роботи номер 1:

## 1. Варіант завдання
Розрахунок варіанту:
* V_2 = База даних: MariaDB
* V_3 = Спосіб конфігурації: через конфігураційні файли
* V_5 = Тематика API: Notes Service

## 2. Архітектура рішення
Проєкт реалізує багаторівневу архітектуру розгортання на базі ОС Linux:
* **Reverse Proxy:** Nginx (приймає запити на 80 порту та проксіює їх на застосунок). Забезпечено блокування доступу до службових ендпоінтів (`/health`).
* **Application Server:** Uvicorn (FastAPI), інтегрований через Systemd Socket Activation (порт 8000, `fd=3`).
* **База даних:** MariaDB. Налаштовано автоматичне виконання міграцій бази даних (`ExecStartPre`) перед кожним запуском основного сервісу.
* **Автоматизація:** Розроблено Bash-скрипт `install.sh` для повного налаштування середовища з нуля (встановлення залежностей, створення користувачів, налаштування БД та сервісів).

## 3. Документація API (Notes Service)
Застосунок надає наступні основні ендпоінти:
* `GET /` - Головна HTML-сторінка
* `GET /notes` - Отримати список усіх нотаток
* `POST /notes` - Створити нову нотатку
* `GET /docs` - Swagger UI для тестування API

## 4. Інструкція з автоматичного розгортання
Для розгортання проєкту на чистій віртуальній машині (Ubuntu/Debian) виконайте наступні команди:

1. Клонуйте репозиторій:
   git clone [посилання_на_твій_репозиторій]
   cd [назва_папки_репозиторію]

2. Надайте права на виконання та запустіть скрипт встановлення:
   chmod +x install.sh
   sudo ./install.sh

Скрипт автоматично встановить Nginx, MariaDB, Python-залежності, створить необхідних користувачів та запустить сервіс.

## 5. Доступи для тестування
Після виконання скрипта створено локальних користувачів для перевірки:
* **teacher** (пароль: `12345678`)
* **operator** (пароль: `12345678`) — має права `sudo` виключно для керування сервісом застосунку (`systemctl start/stop/restart/status mywebapp`) та веб-сервером (`systemctl reload nginx`).
* Файл-маркер із заліковою книжкою згенеровано за шляхом `/home/student/gradebook`.

# Звіт з лабораторної роботи номер 2:

## Дослідницька частина
### Dockerfile (неоптимальний)

```dockerfile
FROM python:3.12
WORKDIR /app
COPY . .
RUN pip install -r requirements/backend.in
CMD ["uvicorn", "spaceship.main:app", "--host", "0.0.0.0", "--port", "8080"]
```

#### Результати:
Час збірки: ~28–29 с
Розмір: 1.82 GB
Аналіз

Образ дуже великий, оскільки містить: всі залежності , кеші

### Оптимізація Dockerfile 

```dockerfile
FROM python:3.10-alpine
WORKDIR /app

COPY requirements/backend.in .
RUN pip install --no-cache-dir -r backend.in

COPY . .

CMD ["uvicorn", "spaceship.main:app", "--host", "0.0.0.0", "--port", "8080"]
```

#### Результати:
Перша збірка: ~33 с
Повторна збірка: 0.8–1.8 с
Розмір: 233 MB

Використовується кеш Docker , залежності не перевстановлюються ,значно менший образ (Alpine)

### DNS

### Результат (Ubuntu):
10.0.0.50 myservice.internal.corp
##### Логи DNS
myservice.internal → NXDOMAIN
myservice.internal.corp → 10.0.0.50

Ubuntu автоматично додає .corp (search domain).
DNS спочатку не знаходить ім’я, але після доповнення — працює.

Go образ (без оптимізації)
```dockerfile
FROM golang:1.22

WORKDIR /app

COPY . .

RUN go build -o fizzbuzz

CMD ["./fizzbuzz", "serve"]
```

### Результати
Час: ~60 с
Розмір: 1.33 GB
Аналіз

Містить:

Go компілятор ,вихідний код ,зайві файли

## Порівняння образів

Python (Debian) -	1.82 GB ,
Python (Alpine) - 233 MB,
Go (full) -	1.33 GB

### Висновок
Використання Alpine значно зменшує розмір образу.
Правильний порядок шарів прискорює повторну збірку.
Docker кеш дозволяє зменшити час до <1 секунди.
DNS поводиться по-різному залежно від базового образу.
Неоптимізовані образи містять багато зайвих файлів.

## Практична частина:
Для запуску всього стеку на будь-якій машині з встановленим Docker:

Запустіть контейнери у фоновому режимі:
```docker-compose up -d --build```

# Звіт до лабораторної роботи 3

---

# 1. Структура проєкту

У проєкті змінилась структура:

```text
.github/workflows/
scripts/
src/
docker-compose.yml
dockerfile
requirements.txt
README.md
```

---

# 2. Реалізація CI (Continuous Integration)

Для автоматичної перевірки коду було створено workflow `ci.yml`.

CI запускається при:
- push у main
- pull request у main

Основні етапи CI:
- встановлення Python
- встановлення залежностей
- lint перевірка
- запуск тестів
- coverage аналіз

---

## 2.1 Workflow CI

```yaml
name: CI

on:
  push:
    branches: [ "main" ]

jobs:
  lint-test:
    runs-on: ubuntu-latest
```

---

# 3. Перевірка коду (Lint)

Було використано:
- flake8
- shellcheck
- yamllint
- hadolint

---

## 3.1 Python lint

```yaml
- name: Python lint
  run: |
    flake8 src --max-line-length=120
```

---

## 3.2 Dockerfile lint

```yaml
- name: Dockerfile lint
  uses: hadolint/hadolint-action@v3.1.0
```

---

# 4. Автоматичне тестування

Для тестування використовувався pytest.

---

## 4.1 Тестування FastAPI

```python
from fastapi.testclient import TestClient
from src.infrastructure.main import app

client = TestClient(app)

def test_docs_available():
    response = client.get("/docs")
    assert response.status_code == 200
```

---

# 5. Coverage перевірка

Було реалізовано coverage контроль:

```yaml
- name: Run tests with coverage
  run: |
    pytest --cov=src --cov-report=term --cov-report=html --cov-fail-under=40
```

Мінімальний coverage:

```text
40%
```

---

# 6. Docker контейнеризація

Для застосунку був створений Dockerfile.

---

## 6.1 Dockerfile

```dockerfile
FROM python:3.12

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["uvicorn", "src.infrastructure.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

# 7. Docker Compose

Для запуску застосунку та MariaDB використовувався docker-compose.

---

## 7.1 docker-compose.yml

```yaml
services:
  db:
    image: mariadb:11
    container_name: sdt-db

  app:
    image: ghcr.io/shizulka/sdt:latest
    container_name: sdt-app
```

---

# 8. GitHub Container Registry (GHCR)

Docker image автоматично завантажувався у GitHub Container Registry.

---

## 8.1 Docker build workflow

```yaml
- name: Build and push
  uses: docker/build-push-action@v6
```

---

# 9. Self-hosted Runner

Для виконання deploy workflow використовувався self-hosted runner на окремій віртуальній машині Linux Mint.

Runner був налаштований через:

```bash
./config.sh
./run.sh
```

---

# 10. Реалізація CD (Continuous Deployment)

Deploy запускався автоматично після створення git tag:

```bash
git tag -a v1.0.16 -m "redeploy"
git push origin v1.0.16
```

---

# 11. Deploy Script

Було реалізовано автоматичний deploy через SSH.

---

## 11.1 deploy.sh

```bash
ssh "$TARGET_USER@$TARGET_HOST" "
  cd /opt/mywebapp &&
  docker pull '$IMAGE_TAG' &&
  sudo systemctl restart sdt-app
"
```

---

# 12. Systemd Service

Для автоматичного запуску контейнерів використовувався systemd service.

---

## 12.1 sdt-app.service

```ini
[Unit]
Description=SDT application container

[Service]
WorkingDirectory=/opt/mywebapp
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
```

---

# 13. Перевірка роботи застосунку

Після deploy було перевірено:
- запуск контейнерів
- доступність FastAPI
- роботу Swagger документації

---

## 13.1 Перевірка контейнерів

```bash
docker ps
```

---

## 13.2 Перевірка FastAPI

```bash
curl http://localhost:8000/docs
```


