from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
from sqlalchemy.orm import Session
from src.infrastructure.models import Note , Base


SQLALCHEMY_DATABASE_URL = "mysql+pymysql://app:12345678@127.0.0.1:3306/mywebapp"

engine = create_engine(SQLALCHEMY_DATABASE_URL, pool_pre_ping=True)

Base.metadata.create_all(bind=engine)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def db_ping(db: Session) -> None:
    db.execute(text("SELECT 1"))