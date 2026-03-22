from src.infrastructure.database import get_db
from src.service.note_service import NoteService
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

router = APIRouter()

@router.post("/create")
def create_note (title : str , conten : str ,  db :Session = Depends (get_db)):
    service = NoteService(db)
    note = service.create_note(title=title , conten=conten )

    return {"name" : note.title , "conten" : note.conten }

@router.get ("/all_note")
def get_all_note ( db :Session = Depends (get_db)):
    service = NoteService(db)
    notes = service.get_all_note()

    print("dani" , notes)
    return notes