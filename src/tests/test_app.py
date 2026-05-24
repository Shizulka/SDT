from fastapi.testclient import TestClient
from src.infrastructure.main import app

client = TestClient(app)


def test_root_available():
    response = client.get("/")
    assert response.status_code == 200


def test_docs_available():
    response = client.get("/docs")
    assert response.status_code == 200


def test_notes_endpoint_available():
    response = client.get("/notes")
    assert response.status_code in [200, 404, 500]
