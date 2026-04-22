import argparse
import os

from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from contextlib import asynccontextmanager
from src.infrastructure.database import engine
from src.infrastructure.models import Base
import uvicorn
from src.infrastructure.database import get_db
from src.controller import note_control 

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("App starting...")
    yield
    print("App shutting down...")


app = FastAPI(lifespan=lifespan)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument("--db-url", type=str, default="mysql+pymysql://app:12345678@127.0.0.1:3306/mywebapp")
    parser.add_argument("--migrate-only", action="store_true")
    
    args = parser.parse_args()

    Base.metadata.create_all(bind=engine)


    if "LISTEN_PID" in os.environ:
        uvicorn.run("src.infrastructure.main:app", fd=0)
    else:
        uvicorn.run("src.infrastructure.main:app", host="127.0.0.1", port=args.port)


@app.get("/health")
def health_check(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ok", "message": "робе"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    

@app.get("/alive")
def root():
    return {"message": "робе"}

app.include_router(note_control.router)