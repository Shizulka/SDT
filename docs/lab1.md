
# Лабораторна робота 1  



# 1. Архітектура системи

Усі компоненти системи розгортались на одній Linux Mint 22.3 cinnamon 64bit. віртуальній машині.

Архітектура:

```text
client → nginx (reverse proxy) → web application → SQL database
```

Мережеві обмеження:

| Компонент | Адреса | Порт |
|---|---|---|
| nginx | 0.0.0.0 | 80 |
| web app | 127.0.0.1 | 8000 |
| SQL database | 127.0.0.1 | 3306 |

---

# 2. Вибір варіанту

Було реалізовано варіант:

```text
Notes Service
```

Застосунок дозволяє:
- створювати нотатки;
- переглядати список нотаток;
- переглядати окрему нотатку.

---

# 3. Реалізація Web-застосунку

Для реалізації використовувався:
- Python;
- FastAPI;
- SQLAlchemy;
- MariaDB.

---

## 3.1 Структура проєкту

```text
src/
├── controller/
├── infrastructure/
├── repo/
├── service/
├── tests/
```

---

## 3.2 Реалізація API

### GET /notes

Повертає список усіх нотаток.

```python
@app.get("/notes")
def get_notes():
    return notes
```

---

### POST /notes

Створення нової нотатки.

```python
@app.post("/notes")
def create_note(note: NoteCreate):
    ...
```

---

### GET /notes/{id}

Повернення конкретної нотатки.

```python
@app.get("/notes/{id}")
def get_note(note_id: int):
    ...
```

---

# 4. Health Endpoints

Було реалізовано health endpoints.

---

## 4.1 Alive endpoint

```python

@app.get("/health")
def health_check(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ok", "message": "робе"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

---

## 4.2 Ready endpoint

```python
@app.get("/alive")
def root():
    return {"message": "робе"}

```

Endpoint перевіряє:
- доступність бази даних;
- готовність застосунку до роботи.

---

# 5. Робота з базою даних

Для збереження даних використовувалась MariaDB.

---

## 5.1 Підключення до БД

```python
SQLALCHEMY_DATABASE_URL = "mysql+pymysql://app:12345678@localhost:3306/mywebapp"
```

---

## 5.2 Міграція БД

При запуску застосунку автоматично створювались таблиці:

```python
Base.metadata.create_all(bind=engine)
```

---

# 6. Reverse Proxy (Nginx)

Було налаштовано nginx reverse proxy.

---

## 6.1 Конфігурація nginx

```nginx
server {
    listen 80;

    location / {
        proxy_pass http://127.0.0.1:8000;
    }
}
```

Nginx:
- приймав HTTP запити;
- перенаправляв їх до FastAPI;
- працював як reverse proxy.

---

# 7. Systemd Service

Було створено systemd unit для застосунку.

---

## 7.1 mywebapp.service

```ini
[Unit]
Description=MyWebApp

[Service]
User=app
WorkingDirectory=/opt/mywebapp
ExecStart=/usr/bin/python3 -m uvicorn src.infrastructure.main:app --host 127.0.0.1 --port 8000

[Install]
WantedBy=multi-user.target
```

---

# 8. Користувачі системи

Було створено користувачів:

| Користувач | Призначення |
|---|---|
| student | робота над проєктом |
| teacher | перевірка роботи |
| app | запуск застосунку |
| operator | керування сервісом |

---

## 8.1 Обмеження sudo для operator

Користувач `operator` мав право:
- запускати сервіс;
- зупиняти сервіс;
- перезапускати сервіс;
- переглядати статус сервісу;
- reload nginx.

---

# 9. Автоматизація встановлення

Було створено install script.

---

## 9.1 install.sh

```bash
#!/bin/bash

apt update
apt install -y nginx mariadb-server python3 python3-pip

systemctl enable nginx
systemctl start nginx
```

---

# 10. Запуск застосунку

---

## 10.1 Запуск systemd service

```bash
sudo systemctl enable mywebapp
sudo systemctl start mywebapp
```

---

## 10.2 Перевірка статусу

```bash
sudo systemctl status mywebapp
```



