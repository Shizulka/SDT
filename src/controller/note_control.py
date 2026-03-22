from src.infrastructure.database import get_db
from src.service.note_service import NoteService
from datetime import datetime
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session


router = APIRouter()

@router.post("/create")
def create_note (title : str , conten : str ,  db :Session = Depends (get_db)):
    service = NoteService(db)
    note = service.create_note(title=title , conten=conten )

    return {"name" : note.title , "conten" : note.conten }