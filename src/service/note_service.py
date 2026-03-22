from sqlalchemy.orm import Session

from src.infrastructure.models import Note
from src.repo.note_repo import NoteRepository


class NoteService:
    def __init__(self, db: Session ):
        self.repository = NoteRepository(db , Note)
        self.db = db


    def get_all_note(self):
        return self.db.query(Note).all()
    
    def gat_id_note(self , note_id : int):
        return self.repository.get_by_id(note_id)

    def create_note (self , title : str , conten : str ):
        new_note = Note (title=title , conten = conten )

        return self.repository.create(new_note)
    
