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

@router.get ("/note")
def get_all_note ( db :Session = Depends (get_db)):
    service = NoteService(db)
    notes = service.get_all_note()

    result = [{"id": note.note_id, "title" : note.title} for note in notes]
    return result

@router.get ("/note/<id>")
def get_id_note (note_id : int ,  db :Session = Depends (get_db)):
    service = NoteService(db)

    note = service.gat_id_note(note_id)
    return note 