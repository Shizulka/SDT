# Лабараторна робота 3

## Структура :

```text
.github/workflows/
scripts/
src/
docker-compose.yml
dockerfile
requirements.txt
```

Workflow файли:
- `ci.yml`
- `docker-build.yml`
- `deploy.yml`

---

# 2. Демонстрація роботи GitHub Actions

Після виконання команди:

```bash
git push
```

автоматично запускався workflow `CI`.

Було продемонстровано успішне проходження:
- lint перевірок;
- pytest тестів;
- coverage аналізу.

---

# 3. Логи CI

```text
Run PYTHONPATH=. pytest --cov=src --cov-report=term --cov-report=html --cov-fail-under=40

============================= test session starts ==============================
platform linux -- Python 3.12.13, pytest-9.0.3

collected 2 items

src/tests/test_app.py ..                                                [100%]

================================ tests coverage ================================

Name                             Stmts   Miss  Cover
----------------------------------------------------
src/controller/note_control.py      21     10    52%
src/infrastructure/database.py      15      5    67%
src/infrastructure/main.py          38     18    53%
src/infrastructure/models.py        13      0   100%
src/repo/note_repo.py               18     11    39%
src/service/note_service.py         14      6    57%
src/tests/test_app.py                9      0   100%
----------------------------------------------------

TOTAL                              128     50    62%

Required test coverage of 40% reached.
```

---

# 4. Демонстрація Docker Build

Було продемонстровано автоматичну збірку Docker image.

Логи GitHub Actions:

```text
Build and Push Docker Image

latest: Pulling from shizulka/sdt

Digest: sha256:78d37b2f5a9f988e641be3b5071580955b3228dbdd941ca95405c39438a97eba

Status: Downloaded newer image for ghcr.io/shizulka/sdt:latest
```

---

# 5. Демонстрація self-hosted runner

Runner запускався командами:

```bash
cd ~/actions-runner
./run.sh
```

Логи runner:

```text
√ Connected to GitHub

Current runner version: '2.334.0'

Listening for Jobs
```

---

# 6. Демонстрація SSH підключення

Було продемонстровано SSH доступ між runner VM та target VM:

```bash
ssh student@192.168.56.102 "echo OK"
```

Результат:

```text
student@test-VirtualBox:~$ ssh student@192.168.56.102 "echo OK" 
 OK 
 student@test-VirtualBox:~$
```

---

# 7. Демонстрація Docker Compose

На target VM було продемонстровано запуск контейнерів:

```bash
student@test-VirtualBox:/opt/mywebapp$ sudo systemctl restart sdt-app
student@test-VirtualBox:/opt/mywebapp$ docker ps
```

Результат:

```text
CONTAINER ID   IMAGE                         COMMAND                  CREATED         STATUS         PORTS                                         NAMES
3b47c6112810   ghcr.io/shizulka/sdt:latest   "uvicorn src.infrast…"   7 seconds ago   Up 1 second    0.0.0.0:8000->8000/tcp, [::]:8000->8000/tcp   sdt-app
af713cdbae62   mariadb:11                    "docker-entrypoint.s…"   8 seconds ago   Up 7 seconds   3306/tcp                                      sdt-db
```

Було показано:
- контейнер FastAPI застосунку;
- контейнер MariaDB;
- відкритий порт `8000`.

---

# 8. Демонстрація роботи FastAPI

Було продемонстровано доступність Swagger UI:

```bash
student@test-VirtualBox:/opt/mywebapp$ curl http://localhost:8000/docs
```

Результат:

```html
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>FastAPI - Swagger UI</title>
</head>
<body>
<div id="swagger-ui"></div>
</body>
</html>
```

Було підтверджено:
- FastAPI успішно працює;
- Swagger UI доступний;
- API документація генерується автоматично.

---

# 9. Демонстрація systemd service

Було показано статус сервісу:

```bash
sudo systemctl status sdt-app --no-pager
```

Результат:

```text
● sdt-app.service - SDT application container
     Loaded: loaded (/etc/systemd/system/sdt-app.service; enabled)
     Active: active (exited)
```

---

# 10. Демонстрація автоматичного deploy

Deploy запускався після створення git tag:

```bash
git tag -a v1.0.16 -m "redeploy"
git push origin v1.0.16
```

Після цього GitHub Actions автоматично:
- запускав deploy workflow;
- виконував SSH deploy;
- завантажував Docker image;
- перезапускав контейнер;
- запускав FastAPI застосунок.

---

# 11. Логи deploy

```text
Run chmod +x scripts/deploy.sh

Login Succeeded

latest: Pulling from shizulka/sdt

Digest: sha256:78d37b2f5a9f988e641be3b5071580955b3228dbdd941ca95405c39438a97eba

Status: Image is up to date for ghcr.io/shizulka/sdt:latest

Creating sdt-db ... done
Creating sdt-app ... done
```

---
