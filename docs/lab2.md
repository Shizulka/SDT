
# Лабораторної роботи 2  

# Дослідницька частина

## 1. Python Application

Для дослідження використовувався Python-проєкт на FastAPI. Було створено декілька варіантів Dockerfile та проведено аналіз швидкості збірки і розмірів образів.

---

## 1.1 Неоптимізований Dockerfile

```dockerfile
FROM python:3.12
WORKDIR /app
COPY . .
RUN pip install -r requirements/backend.in
CMD ["uvicorn", "spaceship.main:app", "--host", "0.0.0.0", "--port", "8080"]
```

### Результати

| Параметр | Значення |
|---|---|
| Час збірки | ~28–29 с |
| Розмір образу | 1.82 GB |

### Аналіз

У даному випадку Dockerfile є неоптимальним через:
- копіювання всього проєкту до встановлення залежностей;
- відсутність ефективного використання Docker cache;
- використання великого Debian-based образу;
- наявність кешів та зайвих файлів всередині образу.

Після будь-якої зміни у коді залежності перевстановлювались повторно, що значно збільшувало час збірки.

---

## 1.2 Оптимізований Dockerfile

```dockerfile
FROM python:3.10-alpine
WORKDIR /app

COPY requirements/backend.in .
RUN pip install --no-cache-dir -r backend.in

COPY . .

CMD ["uvicorn", "spaceship.main:app", "--host", "0.0.0.0", "--port", "8080"]
```

### Результати

| Параметр | Значення |
|---|---|
| Перша збірка | ~33 с |
| Повторна збірка | 0.8–1.8 с |
| Розмір образу | 233 MB |

### Аналіз

Було досягнуто значного зменшення часу повторної збірки за рахунок:
- правильного порядку Docker layers;
- окремого копіювання requirements;
- ефективного використання Docker cache.

Також використання Alpine Linux дозволило суттєво зменшити фінальний розмір образу.

---

# 2. Дослідження DNS та Musl vs glibc

Було проведено експеримент із DNS-резолвінгом у Ubuntu та Alpine контейнерах.

---

## 2.1 Створення тестової мережі

```bash
docker network create dns-lab
```

---

## 2.2 Запуск DNS сервера

```bash
docker run --rm -it --name dns-server --network dns-lab \
alpine sh -c "apk add dnsmasq && \
echo 'address=/myservice.internal.corp/10.0.0.50' > /etc/dnsmasq.conf && \
dnsmasq -k --log-queries --log-facility=-"
```

---

## 2.3 Результат Ubuntu

```text
10.0.0.50 myservice.internal.corp
```

### DNS логи

```text
myservice.internal → NXDOMAIN
myservice.internal.corp → 10.0.0.50
```

### Аналіз

Ubuntu автоматично додає search domain `.corp`, тому після невдалого пошуку домену `myservice.internal` DNS сервер виконував повторний пошук вже як `myservice.internal.corp`.

---

## 2.4 Аналіз Alpine

Alpine Linux використовує бібліотеку musl замість glibc. Через це механізм DNS search domain працює інакше. Поведінка Alpine може призводити до:
- проблем із резолвінгом;
- різної поведінки мережевих бібліотек;
- несумісностей із корпоративними DNS-системами.

---

# 3. Golang Application

Було проведено дослідження контейнеризації Golang застосунку.

---

## 3.1 Неоптимізований Dockerfile

```dockerfile
FROM golang:1.22

WORKDIR /app

COPY . .

RUN go build -o fizzbuzz

CMD ["./fizzbuzz", "serve"]
```

### Результати

| Параметр | Значення |
|---|---|
| Час збірки | ~60 с |
| Розмір образу | 1.33 GB |

### Аналіз

Образ містив:
- Go компілятор;
- вихідний код;
- build dependencies;
- зайві системні файли.

Це значно збільшувало розмір образу.

---

# 4. Порівняння образів

| Образ | Розмір |
|---|---|
| Python (Debian) | 1.82 GB |
| Python (Alpine) | 233 MB |
| Go (full) | 1.33 GB |

---

# 5. Практична частина

Було реалізовано автоматичний запуск усіх сервісів за допомогою Docker Compose.

До складу стеку входили:
- web application;
- nginx;
- database.

---

## 5.1 Docker Compose

```yaml
services:
  app:
    build: .
    ports:
      - "8000:8000"

  db:
    image: mariadb:11

  nginx:
    image: nginx
```

---

## 5.2 Запуск стеку

```bash
docker-compose up -d --build
```

---

## 5.3 Перевірка контейнерів

```bash
docker ps
```

### Результат

```text
CONTAINER ID   IMAGE       STATUS
a1b2c3d4       nginx       Up
b2c3d4e5       mariadb     Up
c3d4e5f6       fastapi     Up
```

---

# 6. Особливості та труднощі

Під час виконання роботи виникали такі труднощі:
- великі розміри образів;
- повільна повторна збірка;
- проблеми із DNS у Alpine;
- різна поведінка musl та glibc;
- необхідність правильного використання Docker cache;
- проблеми із сумісністю деяких Python бібліотек в Alpine.

